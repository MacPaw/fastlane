require_relative '../../model'
module Spaceship
  class ConnectAPI
    class InAppPurchasePricePoint
      include Spaceship::ConnectAPI::Model

      attr_accessor :customer_price,
                    :proceeds,
                    :price_tier

      attr_accessor :territory

      attr_mapping({
        customerPrice: 'customer_price',
        proceeds: 'proceeds',
        priceTier: 'price_tier',
      })

      def self.type
        return 'inAppPurchasePricePoints'
      end

      ESSENTIAL_INCLUDES = [
        "territory"
      ].join(",")

      #
      # Price Point Equalizations
      #

      def get_equalization_price_points(client: nil, filter: nil, includes: ESSENTIAL_INCLUDES, limit: nil, fields: nil)
        client ||= Spaceship::ConnectAPI
        resps = client.get_in_app_purchase_price_points_equalizations(price_point_id: id, filter: filter, includes: includes, limit: limit, fields: fields).all_pages
        resps.flat_map(&:to_models)
      end
    end
  end
end
