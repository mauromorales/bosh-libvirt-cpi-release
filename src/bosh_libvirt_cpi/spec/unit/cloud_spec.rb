require 'spec_helper'

describe Bosh::LibvirtCloud::Cloud do
  let(:cloud_options) {
    {
      'libvirt' => {
        'host' => 'qemu:///system',
        'pool_name' => 'default'
      }
    }
  }
  let(:connection) { double }

  before(:each) do
      allow(Libvirt).to receive(:open).with('qemu:///system').and_return(connection)
      allow(connection).to receive(:lookup_storage_pool_by_name)
  end

  describe '#new' do
    it 'connects to a hypervisor' do
      Bosh::LibvirtCloud::Cloud.new(cloud_options)

      expect(Libvirt).to have_received(:open).with('qemu:///system')
    end

    it 'expects `host` to be a valid URI' do
      cloud_options['libvirt']['pool_name'] = nil

      expect{
        Bosh::LibvirtCloud::Cloud.new(cloud_options)
      }.to raise_error(ArgumentError, /Invalid Libvirt cloud properties/)
    end

    it 'expects `pool_name` to be a string' do
      cloud_options['libvirt']['pool_name'] = nil

      expect{
        Bosh::LibvirtCloud::Cloud.new(cloud_options)
      }.to raise_error(ArgumentError, /Invalid Libvirt cloud properties/)
    end

    context 'when cloud_options miss the libvirt property' do
      let(:cloud_options) { Hash.new }

      it 'raises an error' do
        expect{
          Bosh::LibvirtCloud::Cloud.new(cloud_options)
        }.to raise_error(ArgumentError, "Invalid Libvirt cloud properties: No 'libvirt' properties specified.")
      end
    end
  end
end
