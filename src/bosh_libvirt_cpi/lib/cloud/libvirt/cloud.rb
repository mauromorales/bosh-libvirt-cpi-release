require 'tmpdir'
require 'libvirt'
require 'yaml'
require 'nokogiri'

module Bosh::LibvirtCloud
  class Cloud < Bosh::Cloud
    def initialize(options)

      libvirt_properties = validate_options(options)

      @connection = Libvirt::open(libvirt_properties['host'])
      @pool = @connection.lookup_storage_pool_by_name(libvirt_properties['pool_name'])
    end

    def create_stemcell(image_path, cloud_properties)
      cid = SecureRandom.uuid

      Dir.mktmpdir do |tmp_dir|
        result = Bosh::Exec.sh("tar -C #{tmp_dir} -xzf #{image_path} 2>&1", :on_error => :return)
        unpacked_image_path = File.join(tmp_dir, 'root.img')
        volume = @pool.create_volume_xml(stemcell_xml(cid, unpacked_image_path))
        upload_volume(volume, unpacked_image_path)
      end

      cid
    end

    def delete_stemcell(stemcell_cid)
      stemcell = @pool.lookup_volume_by_name(stemcell_cid)
      stemcell.delete
    end

    def create_vm(agent_id, stemcell_cid, cloud_properties, networks, disk_cids, environment)
      stemcell = @pool.lookup_volume_by_name(stemcell_cid)
      cid = SecureRandom.uuid
      xml = domain_xml(cid, stemcell.path, networks)
      newdom = @connection.create_domain_xml(xml)
      cid
    end

    def delete_vm(vm_cid)
      vm = @connection.lookup_domain_by_name(domain_name(vm_cid))
      vm.destroy
      #vm.undefine
    end

    def create_disk(size, cloud_properties, vm_cid)
      cid = SecureRandom.uuid
      xml = storage_volume_xml(cid, size, 'MB')
      @pool.create_volume_xml(xml)
      @pool.refresh
      cid
    end

    def delete_disk(disk_cid)
      disk = @pool.lookup_volume_by_name(disk_cid)
      disk.delete
      @pool.refresh

      nil
    end

    def has_disk?(disk_cid)
      if @pool.lookup_volume_by_name(disk_cid)
        return true
      else
        return false
      end
    end

    def has_vm?(vm_cid)
      @connection.lookup_domain_by_name(domain_name(vm_cid))

      true
    rescue Libvirt::RetrieveError
      return false
    end

    def attach_disk(vm_cid, disk_cid)
      vm = @connection.lookup_domain_by_name(domain_name(vm_cid))
      disk = @pool.lookup_volume_by_name(disk_cid)
    
      xml = disk_device_xml(disk.path)

      vm.attach_device(xml)

      nil
    end

    def detach_disk(vm_cid, disk_cid)
      vm = @connection.lookup_domain_by_name(domain_name(vm_cid))
      disk = @pool.lookup_volume_by_name(disk_cid)
    
      xml = disk_device_xml(disk.path)

      vm.detach_device(xml)

      nil
    end

    def get_disks(vm_cid)
      vm = @connection.lookup_domain_by_name(domain_name(vm_cid))
      doc = Nokogiri::XML(vm.xml_desc)

      disks = doc.xpath('//disk/source').map { |node| node['file'] }.map do |path|
        disk = @pool.lookup_volume_by_path(path)
        disk.name
      end
    end

    private

    def validate_options(options)
      raise ArgumentError, "Invalid Libvirt cloud properties: No 'libvirt' properties specified." unless options.has_key?('libvirt')

      schema = Membrane::SchemaParser.parse do
        libvirt_options_schema = {
          'libvirt' => {
            'pool_name' => String
          }
        }
      end
      schema.validate(options)

      options['libvirt']
    rescue Membrane::SchemaValidationError => e
      raise ArgumentError, "Invalid Libvirt cloud properties: #{e.inspect}"
    end

    def upload_volume(volume, image_path)
      stream = @connection.stream
      image_file = File.open(image_path, "rb")
      volume.upload(stream, 0, image_file.size)
      stream.sendall do |_opaque, n|
        begin
          r = image_file.read(n)
          r ? [r.length, r] : [0, ""]
          r ? [0, r] : [0, ""]
        rescue Exception => e
          $stderr.puts "Got exception #{e}"
          [-1, ""]
        end
      end
      stream.finish
    end

    def disk_device_xml(path)
      xml = <<EOF
<disk type='file' device='disk'>
   <driver name='qemu' type='raw' cache='none'/>
   <source file='#{path}'/>
   <target dev='vdb'/>
</disk>
EOF
    end

    def stemcell_xml(name, path)
      xml = <<EOF
<volume>
  <name>#{name}</name>
  <allocation unit="G">0</allocation>
  <capacity unit="b">#{File.size(path)}</capacity>
</volume>
EOF
      xml
    end

    def storage_volume_xml(name, size, unit)
      xml = <<EOF
<volume>
  <name>#{name}</name>
  <allocation unit="G">0</allocation>
  <capacity unit="#{unit}">#{size}</capacity>
</volume>
EOF
      xml
    end

    def network_interfaces_xml(networks)
      xml = ''
      networks.each do |name, network|
        mac_address = generate_unicast_mac_address

        xml += <<EOF
    <interface type='network'>
      <mac address='#{mac_address}'/>
      <source network='default' bridge='virbr0'/>
      <target dev='vnet0'/>
      <model type='virtio'/>
      <alias name='net0'/>
    </interface>
EOF
        libvirt_network = @connection.lookup_network_by_name(name) 
        command = Libvirt::Network::NETWORK_UPDATE_COMMAND_ADD_LAST
        section = Libvirt::Network::NETWORK_SECTION_IP_DHCP_HOST
        flags   = Libvirt::Network::NETWORK_UPDATE_AFFECT_CURRENT
        new_network_dhcp_ip = "<host mac='#{mac_address}' ip='#{network['ip']}'/>"
        libvirt_network.update(command, section, -1, new_network_dhcp_ip, flags)
      end

      xml.strip
    end

    def domain_xml(uuid, volume_path, networks)
      xml = <<EOF
<domain type='kvm'>
  <name>#{domain_name(uuid)}</name>
  <uuid>#{uuid}</uuid>
  <memory unit='KiB'>1048576</memory>
  <vcpu placement='static'>1</vcpu>
  <resource>
    <partition>/machine</partition>
  </resource>
  <os>
    <type arch='x86_64' machine='pc-i440fx-2.8'>hvm</type>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <vmport state='off'/>
  </features>
  <cpu mode='custom' match='exact'>
    <model fallback='forbid'>Skylake-Client</model>
  </cpu>
  <clock offset='utc'>
    <timer name='rtc' tickpolicy='catchup'/>
    <timer name='pit' tickpolicy='delay'/>
    <timer name='hpet' present='no'/>
  </clock>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <pm>
    <suspend-to-mem enabled='no'/>
    <suspend-to-disk enabled='no'/>
  </pm>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='#{volume_path}'/>
      <backingStore/>
      <target dev='vda' bus='virtio'/>
      <alias name='virtio-disk0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x07' function='0x0'/>
    </disk>
    <controller type='usb' index='0' model='ich9-ehci1'>
      <alias name='usb'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x7'/>
    </controller>
    <controller type='usb' index='0' model='ich9-uhci1'>
      <alias name='usb'/>
      <master startport='0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x0' multifunction='on'/>
    </controller>
    <controller type='usb' index='0' model='ich9-uhci2'>
      <alias name='usb'/>
      <master startport='2'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x1'/>
    </controller>
    <controller type='usb' index='0' model='ich9-uhci3'>
      <alias name='usb'/>
      <master startport='4'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x2'/>
    </controller>
    <controller type='pci' index='0' model='pci-root'>
      <alias name='pci.0'/>
    </controller>
    <controller type='virtio-serial' index='0'>
      <alias name='virtio-serial0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x06' function='0x0'/>
    </controller>
    #{network_interfaces_xml(networks)}
    <serial type='pty'>
      <source path='/dev/pts/3'/>
      <target port='0'/>
      <alias name='serial0'/>
    </serial>
    <console type='pty' tty='/dev/pts/3'>
      <source path='/dev/pts/3'/>
      <target type='serial' port='0'/>
      <alias name='serial0'/>
    </console>
    <channel type='spicevmc'>
      <target type='virtio' name='com.redhat.spice.0' state='disconnected'/>
      <alias name='channel0'/>
      <address type='virtio-serial' controller='0' bus='0' port='1'/>
    </channel>
    <input type='mouse' bus='ps2'>
      <alias name='input0'/>
    </input>
    <input type='keyboard' bus='ps2'>
      <alias name='input1'/>
    </input>
    <graphics type='spice' port='5900' autoport='yes' listen='127.0.0.1'>
      <listen type='address' address='127.0.0.1'/>
      <image compression='off'/>
    </graphics>
    <sound model='ich6'>
      <alias name='sound0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0'/>
    </sound>
    <video>
      <model type='vmvga' vram='16384' heads='1' primary='yes'/>
      <alias name='video0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
    </video>
    <redirdev bus='usb' type='spicevmc'>
      <alias name='redir0'/>
      <address type='usb' bus='0' port='1'/>
    </redirdev>
    <redirdev bus='usb' type='spicevmc'>
      <alias name='redir1'/>
      <address type='usb' bus='0' port='2'/>
    </redirdev>
    <memballoon model='virtio'>
      <alias name='balloon0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x08' function='0x0'/>
    </memballoon>
    <rng model='virtio'>
      <backend model='random'>/dev/random</backend>
      <alias name='rng0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x09' function='0x0'/>
    </rng>
  </devices>
  <seclabel type='none' model='none'/>
</domain>
EOF
      xml
    end

    def domain_name(vm_cid)
      "vm-#{vm_cid}"
    end

    def generate_unicast_mac_address
      (["%0.2X"%(rand(256) & 254)] + (1..5).map{"%0.2X"%rand(256)}).join(':')
    end
  end
end
