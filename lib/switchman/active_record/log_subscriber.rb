module Switchman
  module ActiveRecord
    module LogSubscriber
      # sadly, have to completely replace this
      def sql(event)
        self.class.runtime += event.duration
        return unless logger.debug?

        payload = event.payload

        return if 'SCHEMA'.freeze == payload[:name]

        name  = '%s (%.1fms)'.freeze % [payload[:name], event.duration]
        sql   = payload[:sql].squeeze(' '.freeze)
        binds = nil
        shard = payload[:shard]
        shard = "  [#{shard[:database_server_id]}:#{shard[:id]} #{shard[:env]}]" if shard

        unless (payload[:binds] || []).empty?
          binds = "  " + payload[:binds].map { |col,v|
            if col
              [col.name, v]
            else
              [nil, v]
            end
          }.inspect
        end

        if ::Rails.version >= '5'
          name = colorize_payload_name(name, payload[:name])
          sql  = color(sql, sql_color(sql), true)
        else
          if odd?
            name = color(name, self.class::CYAN, true)
            sql  = color(sql, nil, true)
          else
            name = color(name, self.class::MAGENTA, true)
          end
        end

        debug "  #{name}  #{sql}#{binds}#{shard}"
      end
    end
  end
end
