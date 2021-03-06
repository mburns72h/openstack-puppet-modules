require 'spec_helper'

describe 'glance::client' do

  shared_examples 'glance client' do
    it { is_expected.to contain_class('glance::params') }
    it { is_expected.to contain_package('python-glanceclient').with(
        :name   => 'python-glanceclient',
        :ensure => 'present',
        :tag    => ['openstack'],
      )
    }
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end
    include_examples 'glance client'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end
    include_examples 'glance client'
  end
end
