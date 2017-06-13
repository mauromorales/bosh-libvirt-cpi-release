require 'spec_helper'

describe Bosh::LibvirtCloud::Cloud do
  # CPI V1 based on http://bosh.io/docs/cpi-api-v1.html

  describe '#delete_vm' do
    let(:cloud_options) {
      {
        'libvirt' => {
          'host' => 'qemu:///system',
          'pool_name' => 'default'
        }
      }
    }

    let(:connection) { double }
    let(:pool) { double }
    let(:vm) { double }
    let(:vm_cid) { '1234' }

    subject { Bosh::LibvirtCloud::Cloud.new(cloud_options) }

    before(:each) do
      allow(Libvirt).to receive(:open).with('qemu:///system').and_return(connection)
      allow(connection).to receive(:lookup_storage_pool_by_name).and_return(pool)
      allow(connection).to receive(:lookup_domain_by_name).with("vm-#{vm_cid}").and_return(vm)
      allow(vm).to receive(:destroy)
      #allow(vm).to receive(:undefine)
    end

    it 'deletes the vm with given `vm_cid`' do

      subject.delete_vm(vm_cid)
      expect(vm).to have_received(:destroy)
      #expect(vm).to have_received(:undefine)
    end
  end
end
