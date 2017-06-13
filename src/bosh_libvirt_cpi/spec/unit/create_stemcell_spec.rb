require 'spec_helper'

describe Bosh::LibvirtCloud::Cloud do
  # CPI V1 based on http://bosh.io/docs/cpi-api-v1.html

  describe '#create_stemcell' do
    let(:cloud_options) {
      {
        'libvirt' => {
          'host' => 'qemu:///system',
          'pool_name' => 'default'
        }
      }
    }

    let(:image_path) { '/tmp/stemcell/root.img' }
    let(:cloud_properties) { {} }
    let(:connection) { double }
    let(:pool) { double }
    let(:volume) { double }
    let(:volume_xml) { <<EOT
<volume>
  <name>1234</name>
  <allocation unit="G">0</allocation>
  <capacity unit="b">100</capacity>
</volume>
EOT
    }

    subject { Bosh::LibvirtCloud::Cloud.new(cloud_options) }

    before(:each) do
      allow(Dir).to receive(:mktmpdir).and_yield('/tmp/stemcell')
      allow(Libvirt).to receive(:open).with('qemu:///system').and_return(connection)
      allow(connection).to receive(:lookup_storage_pool_by_name).and_return(pool)
      allow(File).to receive(:size).with(image_path).and_return(100)
      allow(pool).to receive(:create_volume_xml).with(volume_xml).and_return(volume)
      allow(SecureRandom).to receive(:uuid).and_return('1234')
      allow(subject).to receive(:upload_volume)
    end

    it 'returns a UUID as `stemcell_cid`' do

      subject.create_stemcell(image_path, cloud_properties)

      expect(subject).to have_received(:upload_volume).with(volume, image_path)
    end
  end
end
