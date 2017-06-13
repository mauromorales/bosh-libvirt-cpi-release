module Bosh

  module LibvirtCloud
  end

  require 'httpclient'
  require 'securerandom'
  require 'membrane'

  require 'common/common'
  require 'common/exec'
  require 'common/thread_pool'
  require 'common/thread_formatter'

  require 'bosh/cpi/registry_client'
  require 'cloud'
  require 'cloud/libvirt/cloud'

  module Clouds
    Libvirt = Bosh::LibvirtCloud::Cloud
  end
end

