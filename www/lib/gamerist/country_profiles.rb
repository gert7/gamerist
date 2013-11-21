module Gamerist
  def country(code)
    case code
    when :EST
      return {
        vat: .21,
        masspaycurrency: :EUR,
        masspayrate: .02,
        masspayfallout: 6.
      }
    else
      return {
        vat: 0.0,
        masspaycurrency: :EUR,
        masspayrate: .02,
        masspayfallout: 6.
      }
    end
  end
end
