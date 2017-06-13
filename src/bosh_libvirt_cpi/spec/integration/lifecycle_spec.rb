require 'spec_helper'

describe 'lifecycle' do
  before(:all) do
    abort('Please export BOSH_LIBVIRT_STEMCELL_PATH to the path of a stemcell in your system') unless ENV['BOSH_LIBVIRT_STEMCELL_PATH']
    @stemcell_path = ENV['BOSH_LIBVIRT_STEMCELL_PATH']
  end

  let(:options) {
    {
        'libvirt' => {
          'host' => 'qemu:///system',
          'pool_name' => 'default'
        }
    }
  }

  let(:agent_id) { "" }
  let(:cloud_properites) { {} }
  let(:networks) { {} }
  let(:disk_cids) { [] }
  let(:environment) { {} }

  it 'does not raise an error' do
    cpi = Bosh::LibvirtCloud::Cloud.new(options)
    #cloud_properties = Psych.load_file(File.join(extracted_stemcell_path, "stemcell.MF"))["cloud_properties"]
    cloud_properties = nil
    stemcell_cid = nil

    Dir.mktmpdir do |tmp_dir|
      result = Bosh::Exec.sh("tar -C #{tmp_dir} -xzf #{@stemcell_path} 2>&1", :on_error => :return)
      image_path = File.join(tmp_dir, "image")
      stemcell_cid = cpi.create_stemcell(image_path, cloud_properties)
    end


    vm_cid = cpi.create_vm(agent_id, stemcell_cid, cloud_properties, networks, disk_cids, environment)
    expect(cpi.has_vm?(vm_cid)).to eq(true)

    disk_cid = cpi.create_disk(1000, {}, vm_cid)

    expect(cpi.has_disk?(disk_cid)).to eq(true)
    cpi.attach_disk(vm_cid, disk_cid)

    sleep 5

    expect(
      cpi.get_disks(vm_cid).include?(disk_cid)
    ).to eq(true)

    # snapshot_cid = cpi.snapshot_disk(disk_cid)

    cpi.detach_disk(vm_cid, disk_cid)

    expect(
      cpi.get_disks(vm_cid).include?(disk_cid)
    ).to eq(false)

    # delete_snapshot
    cpi.delete_disk(disk_cid)
    cpi.delete_vm(vm_cid)
    cpi.delete_stemcell(stemcell_cid)
  end
end
