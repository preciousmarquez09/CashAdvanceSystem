module CashAdvRequestsHelper
    def status_class(status)
      case status
      when 'pending' then 'bg-yellow-200 text-yellow-600 px-2 py-1 text-sm font-semibold rounded capitalize'
      when 'declined' then 'bg-red-200 text-red-600 px-2 py-1 text-sm font-semibold rounded capitalize'
      when 'approved' then 'bg-green-200 text-green-600 px-2 py-1 text-sm font-semibold rounded capitalize'
      when 'released' then 'bg-blue-200 text-blue-600 px-2 py-1 text-sm font-semibold rounded capitalize'
      when 'on-going' then 'bg-orange-200 text-orange-600 px-2 py-1 text-sm font-semibold rounded capitalize'
      when 'settled' then 'bg-purple-200 text-purple-600 px-2 py-1 text-sm font-semibold rounded capitalize'
      else 'bg-gray-300' # Default color
      end
    end
end
  