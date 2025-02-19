module ApplicationHelper
  def format_provider(provider)
    provider.gsub(/[^a-zA-Z]/, "").gsub(/oauth/i, "")
  end

  def flash_class(level)
    base_classes = "p-4 mb-4 rounded-lg shadow-lg text-center"
    case level
    when "notice"
      "#{base_classes} bg-blue-100 text-blue-800"
    when "success"
      "#{base_classes} bg-green-100 text-green-800"
    when "alert"
      "#{base_classes} bg-red-100 text-red-800"
    else
      "#{base_classes} bg-gray-100 text-gray-800"
    end
  end
end
