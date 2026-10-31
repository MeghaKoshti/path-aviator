class AddCertificatesToLearningPaths < ActiveRecord::Migration[8.1]
  def change
    # A token means the certificate is published at /c/:token; nil means not (or revoked).
    add_column :learning_paths, :certificate_token, :string
    add_column :learning_paths, :certificate_issued_at, :datetime
    add_index :learning_paths, :certificate_token, unique: true

    # Optional link to the learner's own work for a step (repo, notes, demo), shown on the certificate.
    add_column :path_steps, :evidence_url, :string
  end
end
