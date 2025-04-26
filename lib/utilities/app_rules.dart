// APP RULES AND DOCUMENTATION
// This file serves as documentation for various business rules and statuses in the app

/*
SESSION STATUSES
---------------
1. BOOKED:
   - Initial status when a client books a session
   - Waiting for trainer confirmation
   - Can be cancelled by client without penalty within cancellation window
   - Can be confirmed or rejected by trainer

2. CONFIRMED:
   - Status after trainer accepts/confirms the booking
   - Client can still cancel (may incur cancellation fee depending on timing)
   - Trainer can cancel (should provide reason)
   - Will become 'COMPLETED' after session time passes

3. CANCELLED:
   - session can be cancelled by client or trainer
   - session status can be individual, group, requested etc.
   - also workout plan and meal plan can be cancelled by either client or trainer.
   - Cannot be restored once cancelled

4. COMPLETED:
   - for workout plan and meal plan
   - cannot be modified
   - only client can mark it as completed

5. DELETED:
   - Only available sessions can be deleted
   - Only trainer can delete available sessions
   - Deleted sessions are hidden from client view, and trainer view
   - Can be restored by admin, it is still stored in the database
   - once cancelled, it can be deleted. (workout plan and meal plan)

6. REJECTED:
   - Trainer declined the booking request
   - or client declined session, workout plan, meal plan 

   7. Requested
   - client requested a session
   - trainer can accept or reject
   
TIME RULES
----------
- Sessions must be booked at least 24h in advance
- Free cancellation window: 24h before session start
- Late cancellation fee: Applies if cancelled within 24h
- Session duration must be minimum 30 minutes
- Sessions cannot be booked more than 3 months in advance

BOOKING RULES
------------
- Clients can only book available time slots
- Clients cannot book overlapping sessions
- Trainers cannot have overlapping sessions
- Maximum sessions per day for trainer: 8
- Clients can only book with connected trainers
- Trainers can only confirm bookings from connected clients

PAYMENT RULES
------------
- Payment is required at time of booking
- Cancellation refunds:
  * Full refund if cancelled >24h before
  * Partial/no refund if cancelled <24h before
  * Full refund if trainer cancels
- Trainer payment processing:
  * Processed 24h after session completion
  * Held if session disputed
  * Platform fee: X% of session cost

CONNECTION RULES
---------------
- Trainer must accept client connection request
- Either party can disconnect
- Disconnection hides future sessions
- Historical sessions remain visible
- Reconnection requires new request
*/

// Note: This file is for documentation purposes.
// Actual implementation of these rules should be in respective service files. 