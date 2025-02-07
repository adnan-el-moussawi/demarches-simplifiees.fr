module DossierRebaseConcern
  extend ActiveSupport::Concern

  def rebase!
    if can_rebase?
      transaction do
        rebase
      end
    end
  end

  def can_rebase?
    revision != procedure.published_revision &&
      (brouillon? || accepted_en_construction_changes? || accepted_en_instruction_changes?)
  end

  def pending_changes
    revision.compare(procedure.published_revision)
  end

  private

  def accepted_en_construction_changes?
    en_construction? && pending_changes.all? { |change| accepted_en_construction_change?(change) }
  end

  def accepted_en_instruction_changes?
    en_instruction? && pending_changes.all? { |change| accepted_en_instruction_change?(change) }
  end

  def accepted_en_construction_change?(change)
    if change[:model] == :attestation_template || change[:op] == :move || change[:op] == :remove
      true
    elsif change[:op] == :update
      case change[:attribute]
      when :carte_layers
        true
      when :mandatory
        change[:from] && !change[:to]
      else
        false
      end
    else
      false
    end
  end

  def accepted_en_instruction_change?(change)
    change[:model] == :attestation_template
  end

  def rebase
    # revision we are rebasing to
    target_revision = procedure.published_revision

    # index published types de champ coordinates by stable_id
    target_coordinates_by_stable_id = target_revision
      .revision_types_de_champ
      .includes(:type_de_champ, :parent)
      .index_by(&:stable_id)

    changes_by_op = pending_changes
      .filter { |change| change[:model] == :type_de_champ }
      .group_by { |change| change[:op] }
      .tap { |h| h.default = [] }

    # add champ
    changes_by_op[:add]
      .map { |change| change[:stable_id] }
      .map { |stable_id| target_coordinates_by_stable_id[stable_id] }
      .each { |coordinate| add_new_champs_for_revision(coordinate) }

    # remove champ
    changes_by_op[:remove]
      .each { |change| delete_champs_for_revision(change[:stable_id]) }

    changes_by_op[:update]
      .map { |change| [change, Champ.joins(:type_de_champ).where(dossier: self, type_de_champ: { stable_id: change[:stable_id] })] }
      .each { |change, champs| apply(change, champs) }

    # due to repetition tdc clone on update or erase
    # we must reassign tdc to the latest version
    Champ
      .includes(:type_de_champ)
      .where(dossier: self)
      .map { |c| [c, target_coordinates_by_stable_id[c.stable_id].type_de_champ] }
      .each { |c, target_tdc| c.update_columns(type_de_champ_id: target_tdc.id, rebased_at: Time.zone.now) }

    # update dossier revision
    self.update_column(:revision_id, target_revision.id)
  end

  def apply(change, champs)
    case change[:attribute]
    when :type_champ
      champs.each { |champ| champ.piece_justificative_file.purge_later } # FIX ME: change updated_at
      GeoArea.where(champ: champs).destroy_all

      {
        type: "Champs::#{change[:to].classify}Champ",
        value: nil,
        external_id: nil,
        data:  nil
      }
    when :drop_down_options
      { value: nil }
    when :carte_layers
      # if we are removing cadastres layer, we need to remove cadastre geo areas
      if change[:from].include?(:cadastres) && !change[:to].include?(:cadastres)
        champs.each { |champ| champ.cadastres.each(&:destroy) }
      end

      nil
    end
      &.then { |update_params| champs.update_all(update_params) }
  end

  def add_new_champs_for_revision(target_coordinate)
    if target_coordinate.child?
      # If this type de champ is a child, we create a new champ for each row of the parent
      parent_stable_id = target_coordinate.parent.stable_id
      champs_repetition = Champ
        .includes(:champs, :type_de_champ)
        .where(dossier: self, type_de_champ: { stable_id: parent_stable_id })

      champs_repetition.each do |champ_repetition|
        champ_repetition.champs.map(&:row).uniq.each do |row|
          create_champ(target_coordinate, champ_repetition, row: row)
        end
      end
    else
      create_champ(target_coordinate, self)
    end
  end

  def create_champ(target_coordinate, parent, row: nil)
    params = { revision: target_coordinate.revision }
    params[:row] = row if row
    champ = target_coordinate
      .type_de_champ
      .build_champ(params)
    if parent.is_a?(Dossier)
      parent.champs_public << champ
    else
      parent.champs << champ
    end
  end

  def delete_champs_for_revision(stable_id)
    Champ
      .joins(:type_de_champ)
      .where(dossier: self, types_de_champ: { stable_id: stable_id })
      .destroy_all
  end
end
