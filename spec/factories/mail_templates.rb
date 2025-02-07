FactoryBot.define do
  factory :closed_mail, class: Mails::ClosedMail do
    subject { "Subject, voila voila" }
    body { "Blabla ceci est mon body" }
    association :procedure

    factory :received_mail, class: Mails::ReceivedMail

    factory :refused_mail, class: Mails::RefusedMail

    factory :without_continuation_mail, class: Mails::WithoutContinuationMail

    factory :initiated_mail, class: Mails::InitiatedMail do
      subject { "[demarches-simplifiees.fr] Accusé de réception pour votre dossier nº --numéro du dossier--" }
      body { "Votre administration vous confirme la bonne réception de votre dossier nº --numéro du dossier--" }
    end

    factory :new_draft_mail, class: Mails::NouvelleBrouillonMail

    factory :revert_to_construction_mail, class: Mails::RepasserEnConstructionMail

    factory :revert_to_instruction_mail, class: Mails::RepasserEnInstructionMail
  end
end
