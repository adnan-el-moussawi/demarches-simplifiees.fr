module DossierHelper
  def button_or_label_class(dossier)
    if dossier.accepte?
      'accepted'
    elsif dossier.sans_suite?
      'without-continuation'
    elsif dossier.refuse?
      'refused'
    end
  end

  def highlight_if_unseen_class(seen_at, updated_at)
    if seen_at&.<(updated_at)
      "highlighted"
    end
  end

  def url_for_dossier(dossier)
    if dossier.brouillon?
      brouillon_dossier_path(dossier)
    else
      dossier_path(dossier)
    end
  end

  def url_for_new_dossier(procedure)
    if procedure.brouillon?
      new_dossier_url(procedure_id: procedure.id, brouillon: true)
    else
      new_dossier_url(procedure_id: procedure.id)
    end
  end

  def dossier_form_class(dossier)
    classes = ['form']
    if autosave_available?(dossier)
      classes << 'autosave-enabled'
    end
    classes.join(' ')
  end

  def autosave_available?(dossier)
    dossier.brouillon? && Flipper.enabled?(:autosave_dossier_draft, dossier.user)
  end

  def dossier_submission_is_closed?(dossier)
    dossier.brouillon? && dossier.procedure.close?
  end

  def dossier_display_state(dossier_or_state, lower: false)
    state = dossier_or_state.is_a?(Dossier) ? dossier_or_state.state : dossier_or_state
    display_state = I18n.t(state, scope: [:activerecord, :attributes, :dossier, :state])
    lower ? display_state.downcase : display_state
  end

  def dossier_legacy_state(dossier)
    case dossier.state
    when Dossier.states.fetch(:en_construction)
      'initiated'
    when Dossier.states.fetch(:en_instruction)
      'received'
    when Dossier.states.fetch(:accepte)
      'closed'
    when Dossier.states.fetch(:refuse)
      'refused'
    when Dossier.states.fetch(:sans_suite)
      'without_continuation'
    else
      dossier.state
    end
  end
end
