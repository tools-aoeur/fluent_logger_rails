# frozen_string_literal: true

class HashFormatter
  def call(severity, timestamp, _progname, msg)
    severity_display = if severity.blank?
      'ANY'
    elsif severity.is_a? Integer
      ActiveSupport::Logger::SEV_LABEL[severity]
    else
      severity
    end

    {
      severity: severity_display,
      timestamp: timestamp.in_time_zone.strftime('%Y-%m-%d %H:%M:%S.%3N%z'),
      message: msg.is_a?(String) ? msg.strip : msg,
    }.merge(compact_tags)
  end

  def tagged(*tags)
    add_tags(*tags)
    yield self
  ensure
    remove_tags(*tags)
  end

  def add_tags(*tags)
    tags = tags.first if tags.length == 1

    if tags.is_a? Array
      current_tags[:tags] ||= []
      current_tags[:tags] += tags
    elsif tags.is_a? String
      current_tags[:tags] ||= []
      current_tags[:tags] << tags
    else
      current_tags.merge! tags
    end
  end

  def remove_tags(*tags)
    tags = tags.first if tags.length == 1

    if tags.is_a? Array
      current_tags[:tags] ||= []
      tags.each { |tag| current_tags[:tags].delete(tag) }
    elsif tags.is_a? String
      current_tags[:tags] ||= []
      current_tags[:tags].delete(tags)
    else
      tags.each_key { |key| current_tags.delete(key) }
    end
  end

  def clear_tags!
    current_tags.clear
  end

  def current_tags
    # We use our object ID here to avoid conflicting with other instances
    thread_key = @thread_key ||= "fluent_logger_rails:#{object_id}"
    Thread.current[thread_key] ||= {}
  end

  def compact_tags
    current_tags.delete_if { |_k, v| v.blank? }
  end
end