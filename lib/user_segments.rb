class UserSegments
  SEGMENTS = %w(all_users
                administrators
                proposal_authors
                investment_authors
                feasible_and_undecided_investment_authors
                selected_investment_authors
                winner_investment_authors
                not_supported_on_current_budget
                beta_testers) + Geozone.all.map(&:name).map(&:parameterize).map(&:underscore).sort - ["city"]

  def self.all_users
    User.active
  end

  def self.administrators
    all_users.administrators
  end

  def self.proposal_authors
    author_ids(Proposal.not_archived.not_retired.pluck(:author_id).uniq)
  end

  def self.investment_authors
    author_ids(current_budget_investments.pluck(:author_id).uniq)
  end

  def self.feasible_and_undecided_investment_authors
    unfeasible_and_finished_condition = "feasibility = 'unfeasible' and valuation_finished = true"
    investments = current_budget_investments.where.not(unfeasible_and_finished_condition)
    author_ids(investments.pluck(:author_id).uniq)
  end

  def self.selected_investment_authors
    author_ids(current_budget_investments.selected.pluck(:author_id).uniq)
  end

  def self.winner_investment_authors
    author_ids(current_budget_investments.winners.pluck(:author_id).uniq)
  end

  def self.not_supported_on_current_budget
    author_ids(
      User.where(
                  'id NOT IN (SELECT DISTINCT(voter_id) FROM votes'\
                  ' WHERE votable_type = ? AND votes.votable_id IN (?))',
                  'Budget::Investment',
                  current_budget_investments.pluck(:id)
                )
    )
  end

  def self.beta_testers
    testers = %w(aranacm@madrid.es
                 bertocq@gmail.com
                 mariajecheca@gmail.com
                 alberto@decabeza.es
                 voodoorai2000@gmail.com)

    User.where(email: testers)
  end

  Geozone.all.each do |geozone|
    method_name = geozone.name.parameterize.underscore
    self.define_singleton_method(:"#{method_name}") do
      all_users.where(geozone: geozone)
    end
  end

  def self.user_segment_emails(users_segment)
    UserSegments.send(users_segment).newsletter.pluck(:email).compact
  end

  private

  def self.current_budget_investments
    Budget.current.investments
  end

  def self.author_ids(author_ids)
    all_users.where(id: author_ids)
  end

end
