require 'fastlane_core/provisioning_profile'
require 'spaceship/client'
require 'spaceship/connect_api/models/profile'

module Spaceship
  class ConnectAPI
    MAX_OBJECTS_PER_PAGE_LIMIT = 200
  end
end

module Match
  class Portal
    module Fetcher
      def self.profiles(profile_type:, needs_profiles_devices: false, needs_profiles_certificate_content: false, name: nil)
        includes = []

        profiles_fields = ['profileState', 'uuid' ,'name']
        certificate_fields = []
        fields = {}

        if needs_profiles_devices
          includes = ['devices', 'certificates']
          profiles_fields += ['certificates', 'devices']

          fields[:devices] = 'status'
          certificate_fields += ['expirationDate']
        end

        if needs_profiles_certificate_content
          includes += ['certificates']
          certificate_fields += ['expirationDate', 'certificateContent']
        end

        fields[:certificates] = certificate_fields.uniq.join(',') unless certificate_fields.empty?

        fields[:profiles] = profiles_fields.uniq.join(',')

        profiles = Spaceship::ConnectAPI::Profile.all(
          filter: { profileType: profile_type, name: name }.compact,
          includes: includes.uniq.join(','),
          fields: fields,
          limit: Spaceship::ConnectAPI::MAX_OBJECTS_PER_PAGE_LIMIT
        )

        profiles
      end

      def self.certificates(platform:, profile_type:, additional_cert_types:)
        require 'sigh'
        certificate_types = Sigh.certificate_types_for_profile_and_platform(platform: platform, profile_type: profile_type)

        additional_cert_types ||= []
        additional_cert_types.map! do |cert_type|
          case Match.cert_type_sym(cert_type)
          when :mac_installer_distribution
            Spaceship::ConnectAPI::Certificate::CertificateType::MAC_INSTALLER_DISTRIBUTION
          when :developer_id_installer
            Spaceship::ConnectAPI::Certificate::CertificateType::DEVELOPER_ID_INSTALLER
          end
        end

        certificate_types += additional_cert_types

        filter = { certificateType: certificate_types.sort.join(',') } unless certificate_types.empty?

        certificates = Spaceship::ConnectAPI::Certificate.all(
          filter: filter,
          fields: { certificates: 'expirationDate' },
          limit: Spaceship::ConnectAPI::MAX_OBJECTS_PER_PAGE_LIMIT
        ).select(&:valid?)

        certificates
      end

      def self.devices(platform: nil, include_mac_in_profiles: nil)
        platform = platform.to_sym

        device_platform = [
          Spaceship::ConnectAPI::BundleIdPlatform.map(platform),
          'UNIVERSAL' # Universal Bundle ID platform is undocumented as of Oct 4, 2023.
        ].uniq

        device_classes =
          case platform
          when :ios
            [
              Spaceship::ConnectAPI::Device::DeviceClass::IPAD,
              Spaceship::ConnectAPI::Device::DeviceClass::IPHONE,
              Spaceship::ConnectAPI::Device::DeviceClass::IPOD,
              Spaceship::ConnectAPI::Device::DeviceClass::APPLE_WATCH
            ]
          when :tvos
            [
              Spaceship::ConnectAPI::Device::DeviceClass::APPLE_TV
            ]
          when :macos, :catalyst
            [
              Spaceship::ConnectAPI::Device::DeviceClass::MAC
            ]
          else
            []
          end

        if platform == :ios && include_mac_in_profiles
          device_classes += [Spaceship::ConnectAPI::Device::DeviceClass::APPLE_SILICON_MAC]
        end

        filter = {
          status: Spaceship::ConnectAPI::Device::Status::ENABLED,
          platform: device_platform.join(',')
        }

        devices = Spaceship::ConnectAPI::Device.all(
          filter: filter,
          fields: { devices: 'deviceClass,status' },
          limit: Spaceship::ConnectAPI::MAX_OBJECTS_PER_PAGE_LIMIT
        )

        unless device_classes.empty?
          devices = devices.select do |device|
            device_classes.include?(device.device_class) && device.enabled?
          end
        end

        devices
      end

      def self.bundle_ids(bundle_id_identifiers: nil)
        filter = nil
        if bundle_id_identifiers
          if bundle_id_identifiers.kind_of?(Array)
            filter = { identifier: bundle_id_identifiers.join(',') }
          else
            filter = { identifier: bundle_id_identifiers }
          end
        end

        bundle_ids = Spaceship::ConnectAPI::BundleId.all(
          filter: filter,
          fields: { bundleIds: 'identifier,name' },
          limit: Spaceship::ConnectAPI::MAX_OBJECTS_PER_PAGE_LIMIT
        )

        bundle_ids
      end
    end
  end
end
