require 'spec_helper'

describe Bosh::LibvirtCloud::Cloud do
  # CPI V1 based on http://bosh.io/docs/cpi-api-v1.html

  describe '#delete_stemcell' do
    let(:cloud_options) {
      {
        'libvirt' => {
          'host' => 'qemu:///system',
          'pool_name' => 'default'
        }
      }
    }

    let(:image_path) { '/tmp/stemcell/image' }
    let(:cloud_properties) { {} }
    let(:connection) { double }
    let(:pool) { double }
    let(:volume) { double }
    let(:stemcell_cid) { '1234' }
    let(:stemcell) { double }

    subject { Bosh::LibvirtCloud::Cloud.new(cloud_options) }

    before(:each) do
      allow(Libvirt).to receive(:open).with('qemu:///system').and_return(connection)
      allow(connection).to receive(:lookup_storage_pool_by_name).and_return(pool)
      allow(pool).to receive(:lookup_volume_by_name).with(stemcell_cid).and_return(stemcell)
      allow(stemcell).to receive(:delete)
    end

    it 'deletes the stemcell with the given `stemcell_cid`' do
      subject.delete_stemcell(stemcell_cid)

      expect(stemcell).to have_received(:delete)
    end
  end
end
