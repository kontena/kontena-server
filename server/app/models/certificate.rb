class Certificate
  include Mongoid::Document
  include Mongoid::Timestamps

  field :subject, type: String
  field :valid_until, type: DateTime
  field :alt_names, type: Array
  field :encrypted_private_key, type: String, encrypted: true # PEM encoded
  field :certificate, type: String # PEM encoded certificate, no need to encrypt
  field :chain, type: String # Trust chain

  belongs_to :grid

  validates_presence_of :subject, :valid_until
  validates_uniqueness_of :subject, scope: [:grid_id]

  index({ grid_id: 1 })
  index({ subject: 1 })
  index({ grid_id: 1, subject: 1 }, {unique: true})

  def to_path
    "#{self.grid.name}/#{self.subject}"
  end

  # @return [String] Actual certificate and the trust chain bundled together
  def full_chain
    self.certificate + self.chain
  end

  # @return [String] Fullchain and private key bundle, mainly for HAProxy
  def bundle
    self.full_chain + self.private_key
  end

  # @return [Array<String>]
  def all_domains
    [self.subject] + self.alt_names.to_a
  end

end