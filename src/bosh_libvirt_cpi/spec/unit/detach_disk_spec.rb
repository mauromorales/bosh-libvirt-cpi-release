require 'spec_helper'

describe Bosh::LibvirtCloud::Cloud do
  describe '#delete_disk' do
    let(:cloud_options) {
      {
        'libvirt' => {
          'host' => 'qemu:///system',
          'pool_name' => 'default'
        }
      }
    }

    let(:cloud_properties) { {} }
    let(:connection) { double }
    let(:pool) { double }
    let(:volume) { double }
    let(:vm) { double }
    let(:xml) { <<EOL
<disk type='file' device='disk'>
   <driver name='qemu' type='raw' cache='none'/>
   <source file='/disk/path'/>
   <target dev='vdb'/>
</disk>
EOL
    }

    subject { Bosh::LibvirtCloud::Cloud.new(cloud_options) }

    before(:each) do
      allow(Libvirt).to receive(:open).with('qemu:///system').and_return(connection)
      allow(connection).to receive(:lookup_storage_pool_by_name).and_return(pool)
      allow(connection).to receive(:lookup_domain_by_name).with('vm-vm-cid').and_return(vm)
      allow(pool).to receive(:lookup_volume_by_name).with('disk-cid').and_return(volume)
      allow(vm).to receive(:detach_device)
      allow(volume).to receive(:path).and_return('/disk/path')
    end

    it 'dettaches the disk with `disk_cid` from the vm with `vm_cid`' do
      subject.detach_disk('vm-cid', 'disk-cid')

      expect(vm).to have_received(:detach_device).with(xml)
    end
  end
end
