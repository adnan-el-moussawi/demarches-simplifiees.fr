# == Schema Information
#
# Table name: repasser_en_construction_mails
#
#  id           :integer          not null, primary key
#  body         :text
#  subject      :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  procedure_id :integer
#
module Mails
  class RepasserEnConstructionMail < ApplicationRecord
    include MailTemplateConcern

    belongs_to :procedure, optional: false

    SLUG = "repasser_en_construction"
    DEFAULT_TEMPLATE_NAME = "notification_mailer/default_templates/repasser_en_construction_mail"
    DISPLAYED_NAME = I18n.t('activerecord.models.mail.repasser_en_construction_mail.repasser_en_construction')
    DEFAULT_SUBJECT = I18n.t('activerecord.models.mail.repasser_en_construction_mail.default_subject', dossier_number: '--numéro du dossier--', procedure_libelle: '--libellé démarche--')
    DOSSIER_STATE = Dossier.states.fetch(:en_construction)

  end
end
