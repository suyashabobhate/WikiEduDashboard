import React from 'react';
import { connect } from 'react-redux';

import Loading from '../common/loading';
import Notifications from '../common/notifications';
import Show from './ticket_show';

import {
  createReply,
  deleteTicket,
  fetchTicket,
  fetchTickets,
  readAllMessages,
  selectTicket } from '../../actions/tickets_actions';

export class TicketShow extends React.Component {
  componentDidMount() {
    const id = this.props.match.params.id;
    const ticket = this.props.tickets.byId[id];

    if (ticket) {
      this.props.readAllMessages(ticket);
      return this.props.selectTicket(ticket);
    }

    this.props.fetchTicket(id).then(() => {
      this.props.readAllMessages(this.props.tickets.selected);
    });
  }

  render() {
    if (!this.props.tickets.selected.id) return <Loading />;

    return (
      <div>
        <Notifications />
        <Show
          deleteTicket={this.props.deleteTicket}
          createReply={this.props.createReply}
          currentUser={this.props.currentUserFromHtml}
          fetchTicket={this.props.fetchTicket}
          ticket={this.props.tickets.selected}
        />
      </div>
    );
  }
}

const mapStateToProps = ({ currentUserFromHtml, tickets }) => ({
  currentUserFromHtml,
  tickets
});

const mapDispatchToProps = {
  createReply,
  deleteTicket,
  fetchTicket,
  fetchTickets,
  readAllMessages,
  selectTicket
};

const connector = connect(mapStateToProps, mapDispatchToProps);
export default connector(TicketShow);
