require 'spec_helper'

describe Bosh::LibvirtCloud::Cloud do
  describe '#has_disk?' do
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

    subject { Bosh::LibvirtCloud::Cloud.new(cloud_options) }

    before(:each) do
      allow(Libvirt).to receive(:open).with('qemu:///system').and_return(connection)
      allow(connection).to receive(:lookup_storage_pool_by_name).and_return(pool)
      allow(pool).to receive(:lookup_volume_by_name).with(disk_cid).and_return(volume)
    end

    context 'with an existing disk' do
      let(:disk_cid) { 'existing-disk-cid' }
      let(:volume) { double }
      
      it 'returns true' do
        expect(
          subject.has_disk?(disk_cid)
        ).to eq(true)
      end
    end

    context 'with a missing disk' do
      let(:disk_cid) { 'missing-disk-cid' }
      let(:volume) { nil }

      it 'returns false' do
        expect(
          subject.has_disk?(disk_cid)
        ).to eq(false)
      end
    end
  end
end
