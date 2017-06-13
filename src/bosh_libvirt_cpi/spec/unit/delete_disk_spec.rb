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

    subject { Bosh::LibvirtCloud::Cloud.new(cloud_options) }

    before(:each) do
      allow(Libvirt).to receive(:open).with('qemu:///system').and_return(connection)
      allow(connection).to receive(:lookup_storage_pool_by_name).and_return(pool)
      allow(pool).to receive(:lookup_volume_by_name).with('disk-cid').and_return(volume)
      allow(volume).to receive(:delete)
      allow(pool).to receive(:refresh)
    end

    it 'removes the disk with the given `disk_cid`' do
      subject.delete_disk('disk-cid')

      expect(pool).to have_received(:lookup_volume_by_name).with('disk-cid')
      expect(volume).to have_received(:delete)
    end
  end
end
