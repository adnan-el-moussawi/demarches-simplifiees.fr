class Logic::IncludeOperator < Logic::BinaryOperator
  def operation = :include?

  def errors(_stable_ids = nil)
    result = []

    if @left.type != :enum && @left.type != :enums
      result << { type: :required_list }
    elsif !@left.options.map(&:second).include?(@right.value)
      result << {
        type: :not_included,
        stable_id: @left.stable_id,
        right: @right
      }
    end

    result
  end
end
