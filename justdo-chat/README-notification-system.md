# Triggering notifications following a certain period in-which a channel remains in an involuntary unread state for a subscribed memeber

Whenever a channel state for a subscriber is set to unread as a result of an action by another
member, we say that it is in an *Involuntary Unread State* for that subscriber. It basically
happens anytime the channel becomes unread for any action that isn't the 'set as unread' action
performed by the subscriber himself.

Following a certain period, in which a channel remains in an involuntary unread state for a
subscriber (min_unread_period_ms), we might want to issue an email, a mobile push notification,
or other type of notification to the subscriber, to let him know that unread message/s are
waiting for him in that channel.

In some cases, when a new subscriber is added to a channel by another user, we might want to send
a notification about the unread messages in that channel, if they were sent durign a certain period
in which we consider them 'new'. (Simple obvious example: shortly after a message is sent in a task
a new subscriber is added by another member of the task, the new subscriber should be notified
about the new message even though it was sent before he became a subscriber).

Below are the considerations taken into account when desigining a solution for that need and
the solution designed.

Notes:

* At the moment we deal only with notifications that are sent once per switch to involuntary
unread state, meaning, if more messages will be sent to the channel, after an unread notification
of a specific type sent already, no further messages will be sent for that channel for that specific
notification type. In the future, we can add support for additional notifications, but that will
probably involve an introduction of additional indicator fields to be done efficiently.
* Periodic notifications (one/twice a day, etc.) aren't covered by this solution as they are
inherently different.

## Requirements:

* The exact same approach should be used for Email, and Mobile push notifications.
* If new fields are added to the subscribers sub-doc, existing publications observers should
exclude them to avoid redundant calls to them.
* Need simple, indexable query, that returns only channels that needs processing.
* Need to avoid sending a notification when the user mark the channel as unread by himself.
* Sending message, shouldn't involve more write requests (Note 1) than it requires
now, nor use more resources.
* Marking channel as read for subscriber shouldn't inolve more write requests (Note 1) than
it requires now, nor use more resources.
* Processing a channel that has notifications to process, should involve only 1 write
when updating the subscribers fields but still be thread safe (not risking overwriting data
that was written by others between the time processing begun and finished).
* Need to remember the fact that subscription doesn't imply access right to the channel.
* Solution should be useful for all types of channels and not only the tasks channels.

* Optimization wise:

 * Design the solution so only one request will be required to find all the subscribers that subscribed for immediate message.
 * Need one request to fetch the task (or other channel related resources for other channels types) to determine subscribers access right.

* The above means that as a result of sending a message to a channel, regardless of the channels subscribers we are performing:
 * 1 read for users details
 * 1 read for required related docs data for access rights.
 * 1 write to update the channel that we processed the required emails.

The key here is to avoid O(n) updates/reads where n is the subscribers count.

Notes:

1. More fields can be affected but using the same request.

## Solution Design:

### Tracking the time a channel changes its state to involuntary unread for a subscriber

Since we give a certain 'grace period' (min_unread_period_ms) during which we let the user
read the channel without issuing a notification, we need to track when a channel became unread
involuntarily for a subscriber. We do that using a new field in the subscriber object:

```
iv_unread: Date()
```

Whenever the channel unread state becomes false for a subscriber, we $unset his iv_unread field.

Note the min_unread_period_ms is different for each notification type.

### Tracking the type of involuntary unread cause

The cause that made a channel involuntary unread for a user affect the notification we are sending
for it. For example, if a channel became involuntarily unread due to a new message sent by another
user to that channel, we will include in the notification messages starting from the sent message
(inclusive). But, if a channel became involuntarily unread due to addition of the subscriber as
a new subscriber we will regard messages sent during a period before that time as eligible for
inclusion in notifications (discussed with example in the intro section of that file).

Because of that, we need to keep a record for the cause that made the channel involuntarily unread
for a subscriber.

We that adding another field to the subscriber object:

```
iv_unread_type: String, allowed values: "new-sub" / "new-msg"
```

Whenever the channel unread state becomes false for a subscriber, we $unset his iv_unread_type field.

### Unread Notification Type Indicator Field

For each unread notification type (email, android push notificatino, etc.) we will have a field
that might be set for each subscriber object called Notification Type Indicator or Indicator Field
for short.

That indicator stores a date and is used by us to track whether the unread notifications process
type handled it.

The date is the date in which that Involuntary Unread state handled.

Handling doesn't mean that a notification sent, it means that we checked whether or not a notification
should be sent, and no further checks are required (job done).

The indicator fields for each process are as follows:

  * For the unread channels email processor: subscribers.$.unread_email_processed
  * For the unread channels push notification processor: subscribers.$.unread_pn_processed

Whenever the channel unread state becomes false for a subscriber, we $unset all his indicator fields.

### User settings fields

Two setting will be added to the user profile under the justdo_chat subdocument:

  * justdo_chat.email_notifications: "" . Can be one of: "off" / "twice-daily" / "once-per-unread"
  * justdo_chat.mobile_push_notifications: true / false .

### Processing Interval and Handling Criteria

Each unread notification type defines an X interval in ms for which we will query the channels
collections for channels with subscribers that has:

* iv_unread > wait period defined for the notification type
* AND no Indicator Field for the notification type

We call this the Handling Criteria.

### Processing

For the channels returned by the Handling Criteria, we will loop through all the subscribers, and
for those that don't have the indicator field we will check their settings (we will use one mongo
call to get all these users docs) to see if a notification should be sent to them.

If we need to send notification, we will ensure the user has access to the channel, we will skip the
subscriber notification otherwise (this should be done by using the Channel Object access mechanisms,
this should be done in a way that external docs used to determine access, such as the task doc for
tasks channel, will be requested only once).

If the user has permission, we process the notification.

Once we are done, we need to see whether there was any change during the time we processed the notifications, in particular, whether new subscribers added, and whether these subscribers
need to get notification as well. If so we need to process notifications for them as well as descirbed
above.

Once all is done we use one mongo call to set the indicatior field for all the channels subscribers
that fit our Handling Criteria to the processing time.

The set as read operation done by user will, from now on, remove all the indicator fields for the
subscriber, so in the next time the channel will become unread for the user, a notification will be
processed.

## Risk of duplicate notifications

Since we don't want to perform n writes, where n is the number of subscribers fulfilling the Handling
Criteria, we mark all the subscribers as handled (set the indicator field exists) once we finish
processing all of them. If the server collapses in the middle of the handling, members for which
notification had been issued already, will receive another notification.


# DEPRECATED


### Tracking the date of the first message we consider as unread per subscriber

When deciding what messages to notify the subscriber about, we can't rely on the `last_read` field
that existed before the design of the unread notifications system. For the reason that a user might
have never read a channel we want to notify him about (e.g. a new subscriber). Also, the `last_read`
field is used to show the subscriber the breakpoint where he stopped reading the channel last time,
it has to be the actual, real, last place the user stopped reading and not arbitrary point set by us.

Because of that, we have to introduce a new optional field to the subscribers object, to track
the date of the first message that we want to permit its inclusion in unread notifications.
How many messages will be included in an unread notification, is up to the specific notification type,
but all the messages that sent on that date or after will be candidates for inclusion in the unread
notifications.

The field is:

```
subscriber.first_iv_unread_msg_date: Date()
```

Short for first involuntary unread message date.

Note that the message we want to notify the subscriber about might have been sent in an earlier
time than the time in which we set the channel as iv_unread, example is where a new subscriber
is added by another subscriber (see next section). Therefore, we can't use the `iv_unread` field
described above, which is used to track the 'grace period' described in the previous section.

The `first_iv_unread_msg_date` field only tracks the messages that we permit their inclusion in an
involuntary unread notifications.

### Tracking the recent X messages dates

For new subscribers, added by other members, we need to decide whether or not notifications
should be sent, and if so, which messages they should include.

Each notification type will behave differently on that. 3 notifications type options controls that:

* new_subscribers_notifications - whether or not notifications are sent at all for new subscribers.
* new_subscribers_notifications_threshold_ms - Messages that are older than the set miliseconds will be excluded from the type unread notifications (if we left with 0, no notification will be sent).
* new_subscribers_notifications_max_messages - The maximal amount of messages to include in the notifcation sent to new subscribers (relevant if new_subscribers_notifications_threshold_ms criteria
left us with enough messages).

Now, we want to set the `first_iv_unread_msg_date` field according to the above requirements
without querying the messages collection.

For that, we are going to maintain a new field in the channel document that tracks the dates of the
last X messages that were sent to the channel. The field will be called:

    channel.recent_messages_dates

It will be an array of dates.

We will use Mongo's $push $slice operator to make channel.recent_messages_ts a FIFO queue of size
X.

We keep the last X messages in order to efficiently obtain the dates of the first message that
needs to be included in the unread notification sent to newly added subscribers (if any).

### Processing Interval and Handling Criteria

Every x seconds, depending on needs (probably 1 min for emails, 5 secs for PN), we will query
the channels collections for channels with subscribers that has:

unread == true
AND first_unread_ts older > wait period defined for the notification type
AND no Indicator Field for the notification type

We call this the Handling Criteria.


