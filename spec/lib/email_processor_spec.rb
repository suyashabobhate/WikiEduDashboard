# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/email_processor"

describe EmailProcessor do
  describe '#process' do
    let(:course) { create(:course) }

    let(:student) { create(:user, username: 'student', email: 'student@email.com') }
    let(:student_courses_user) { create(:courses_user, user: student, course: course) }

    let(:expert) { create(:admin, greeter: true, username: 'expert', email: 'expert@wikiedu.org') }
    let(:expert_courses_user) do
      create(:courses_user, user: expert, course: course, role: 4)
    end

    it 'creates an associated Ticket and Message' do
      expect(TicketDispenser::Ticket.all.count).to eq(0)
      expect(TicketDispenser::Message.all.count).to eq(0)

      email = create(:email,
                     to: [{ email: expert.email }],
      from: { email: student.email })
      processor = described_class.new(email)
      processor.process

      expect(TicketDispenser::Ticket.all.count).to eq(1)
      expect(TicketDispenser::Message.all.count).to eq(1)

      ticket = TicketDispenser::Ticket.first
      expect(ticket.owner).to eq(expert)

      message = ticket.messages.first
      expect(message.sender).to eq(student)
    end

    it 'does not set the sender if it cannot be found' do
      email = create(:email,
                     to: [{ email: expert.email }],
      from: { full: 'other@email.com', email: 'other@email.com' })
      processor = described_class.new(email)
      processor.process

      expect(TicketDispenser::Ticket.all.count).to eq(1)
      expect(TicketDispenser::Message.all.count).to eq(1)

      ticket = TicketDispenser::Ticket.first
      expect(ticket.owner).to eq(expert)

      message = ticket.messages.first
      expect(message.sender).to eq(nil)
      expect(message.content).to include('From other@email.com')
    end

    it 'does not set an owner if it is not addressed to a Wikipedia Expert' do
      email = create(:email,
                     to: [{ email: 'unknown@wikiedu.org' }],
                     from: { email: student.email })
      processor = described_class.new(email)
      processor.process

      expect(TicketDispenser::Ticket.all.count).to eq(1)
      expect(TicketDispenser::Message.all.count).to eq(1)

      ticket = TicketDispenser::Ticket.first
      expect(ticket.owner).to eq(nil)
    end

    it 'can thread a message with the right ticket' do
      ticket = TicketDispenser::Dispenser.call(
        content: 'Message content',
        owner_id: expert.id,
        sender_id: student.id
      )
      email_body = ''"Hi there,
      Thanks for responding! ...

      -- DO NOT DELETE ANYTHING BELOW THIS LINE --
      **ref_#{ticket.reference_id}_ref**
      -- REPLY ABOVE THIS LINE --
      "''
      email = create(:email,
                     to: [{ email: expert.email }],
      from: { email: student.email },
      body: email_body,
      raw_body: email_body)
      processor = described_class.new(email)
      processor.process

      expect(ticket.messages.length).to eq(2)
    end
  end
end
