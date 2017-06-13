require 'spec_helper'

describe Bosh::LibvirtCloud::Cloud do
  describe '#create_disk' do
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
      allow(SecureRandom).to receive(:uuid).and_return('1234')
      allow(pool).to receive(:create_volume_xml)
      allow(pool).to receive(:refresh)
    end

    it 'returns a `disk_cid`' do
      xml = <<EOF
<volume>
  <name>1234</name>
  <allocation unit="G">0</allocation>
  <capacity unit="MB">1000</capacity>
</volume>
EOF

      subject.create_disk(1000, {}, nil)

      expect(pool).to have_received(:create_volume_xml).with(xml)
      expect(pool).to have_received(:refresh)
    end
  end
end
