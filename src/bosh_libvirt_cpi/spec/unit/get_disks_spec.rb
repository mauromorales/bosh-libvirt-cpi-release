require 'spec_helper'

describe Bosh::LibvirtCloud::Cloud do
  describe '#get_disks' do
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
    let(:first_volume) { double('volume', name: 'vol-1-id') }
    let(:second_volume) { double('volume', name: 'vol-2-id') }
    let(:vm) { double }
    let(:vm_xml) {<<EOL
<devices>
  <disk type='file' device='disk'>
    <source file='/path/to/disk/1'/>
  </disk>
  <disk type='file' device='disk'>
    <source file='/path/to/disk/2'/>
  </disk>
</devices>
EOL
    }

    subject { Bosh::LibvirtCloud::Cloud.new(cloud_options) }

    before(:each) do
      allow(Libvirt).to receive(:open).with('qemu:///system').and_return(connection)
      allow(connection).to receive(:lookup_storage_pool_by_name).and_return(pool)
      allow(connection).to receive(:lookup_domain_by_name).with('vm-vm-cid').and_return(vm)
      allow(pool).to receive(:lookup_volume_by_path).with('/path/to/disk/1').and_return(first_volume)
      allow(pool).to receive(:lookup_volume_by_path).with('/path/to/disk/2').and_return(second_volume)
      allow(vm).to receive(:xml_desc).and_return(vm_xml)
    end

    it 'returns an array of `disk-cids` from the given `vm_cid`' do
      disks = subject.get_disks('vm-cid')

      expect(disks).to match(['vol-1-id', 'vol-2-id'])
    end
  end
end

