require 'spec_helper'

describe Bosh::LibvirtCloud::Cloud do
  describe '#has_vm?' do
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
    end

    context 'with an existing vm' do
      before(:each) do
        allow(connection).to receive(:lookup_domain_by_name).with("vm-#{vm_cid}").and_return(vm)
      end

      let(:vm_cid) { 'existing-vm-cid' }
      let(:vm) { double }
      
      it 'returns true' do
        expect(
          subject.has_vm?(vm_cid)
        ).to eq(true)
      end
    end

    context 'with a missing vm' do
      before(:each) do
        allow(connection).to receive(:lookup_domain_by_name).with("vm-#{vm_cid}").and_raise(Libvirt::RetrieveError)
      end

      let(:vm_cid) { 'missing-vm-cid' }
      let(:vm) { nil }

      it 'returns false' do
        expect(
          subject.has_vm?(vm_cid)
        ).to eq(false)
      end
    end
  end
end
