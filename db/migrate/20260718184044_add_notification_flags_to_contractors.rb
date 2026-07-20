class AddNotificationFlagsToContractors < ActiveRecord::Migration[7.0]
  # Flagi per-zdarzenie pozwalające kontraktorowi wyłączyć poszczególne
  # powiadomienia adresowane do niego (zdarzenia A/B/E/F systemu powiadomień).
  # Globalne `are_notifications_enabled` pozostaje nadrzędne (bramka AND w
  # Notifications::RecipientResolver). Przypomnienia C/D idą na adres instytucji
  # i nie są sterowane tymi flagami.
  #
  # UWAGA (produkcja): `Contractors` to duża, współdzielona tabela legacy —
  # ADD COLUMN z NOT NULL/DEFAULT należy wykonać w oknie serwisowym lub przez
  # online-DDL. Default `true` zachowuje dotychczasowe zachowanie (brak wyciszeń).
  def change
    add_column :Contractors, :allow_sample_acceptance_notifications, :boolean, default: true, null: false
    add_column :Contractors, :allow_sample_rejection_notifications,  :boolean, default: true, null: false
    add_column :Contractors, :allow_result_notifications,            :boolean, default: true, null: false
    add_column :Contractors, :allow_sample_registration_notifications, :boolean, default: true, null: false
  end
end
