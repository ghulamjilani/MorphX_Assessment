+function (window) {
    "use strict";

    var PlaylistCableBindings = function (playlist) {
        this.playlist = playlist;
        this.liveChannels = [];
        this.publicSessionsChannel = initSessionsChannel();
        this.bindEvents();
    };
    PlaylistCableBindings.prototype.bindEvents = function () {
        var that = this;
        this.playlist.library.on('trackChanged', function (item) {
            that.unsubscribePrivateChannel();
            that.subscribeToPrivateChannel(item);
        });
        this.playlist.library.on('sync', function () {
            this.each(function (item) {
                if (item.get('type') === 'session' && !item.isFinished()) {
                    var liveStreamChannel = initPrivateLivestreamRoomsChannel(item.get('livestream_channel'));
                    that.liveChannels.push({session: item, channel: liveStreamChannel});

                    liveStreamChannel.bind(privateLivestreamRoomsChannelEvents.livestreamUp, function (data) {
                        console.log(['livestream-up', data]);
                        var isStreaming = that.playlist.library.currentTrack().isStreaming();

                        if (!data.stream_url && !item.get('livestream_url')) {
                            $.ajax({
                                type: 'GET',
                                url: '/sessions/' + item.id + '/get_stream_url',
                                dataType: 'json',
                                contentType: 'application/json',
                                success: function (resp) {
                                    item.set({is_room_active: resp.active, livestream_url: resp.stream_url});
                                    item.set({livestream_up: true});
                                    if (!isStreaming && item.isStreaming() && that.playlist.library.currentTrack() == item) {
                                        that.playlist.changeTrack(item.uniqId());
                                    }
                                }
                            });
                        } else {
                            item.set({livestream_up: true});

                            if (data.active !== null) {
                                item.set({is_room_active: data.active});
                            } else {
                                item.set({is_room_active: true});
                            }
                            if (data.stream_url && !item.get('livestream_url')) {
                                item.set({livestream_url: data.stream_url});
                            }
                            if (!isStreaming && item.isStreaming()) {
                                that.playlist.changeTrack(item.uniqId());
                            }
                        }
                    });
                    liveStreamChannel.bind(privateLivestreamRoomsChannelEvents.livestreamOff, function (data) {
                        console.log(['livestream-off', data]);
                        item.set({livestream_up: false});
                    });
                    liveStreamChannel.bind(privateLivestreamRoomsChannelEvents.livestreamDown, function (data) {
                        console.log(['livestream-down', data]);
                        item.set({livestream_up: false});
                    });
                    liveStreamChannel.bind(privateLivestreamRoomsChannelEvents.roomUpdated, function (data) {
                        console.log(['room_updated', data]);
                        data.start_at = new Date(data.session_start_at);
                        item.set(data);
                    });
                    liveStreamChannel.bind(privateLivestreamRoomsChannelEvents.livestreamMembersCount, function (data) {
                        console.log('livestream_members_count: ' + data.count);
                        item.set({views_count: data.count});
                    });
                    liveStreamChannel.bind(privateLivestreamRoomsChannelEvents.ratingUpdated, function (data) {
                        item.set(data);
                    });

                    // Subscribe to private channel if present to include embed watchers in livestream_members_count
                    that.subscribeToPrivateChannel(item);
                }
            });
        });

        this.publicSessionsChannel.bind(sessionsChannelEvents.sessionStopped, this.onSessionStopped.bind(this));
        this.publicSessionsChannel.bind(sessionsChannelEvents.sessionCancelled, this.onSessionStopped.bind(this));
    };
    PlaylistCableBindings.prototype.onSessionStopped = function (data) {
        var id = Library.prototype.modelId({type: 'session', id: data.session_id}),
            liveChannel;
        this.playlist.library.remove(id);
        liveChannel = _.find(this.liveChannels, function (channelAttrs) {
            console.log(channelAttrs);
            return channelAttrs.session.id === data.session_id;
        });

        if (liveChannel) {
            liveChannel.channel.subscription.unsubscribe();
            this.liveChannels = _.reject(this.liveChannels, function (channelAttrs) {
                return channelAttrs.session.id === data.session_id;
            });
        }
        if (this.privateLiveChannel && this.privateLiveChannel.session.id == data.session_id) {
            this.unsubscribePrivateChannel();
        }
    };
    PlaylistCableBindings.prototype.subscribeToPrivateChannel = function (item) {
        if (item.get('private_livestream_channel') && item.isPlaying()) {
            var privateLiveStreamChannel = initPrivateLivestreamRoomsChannel(item.get('private_livestream_channel'));
            this.privateLiveChannel = {session: item, channel: privateLiveStreamChannel};
        }
    };

    PlaylistCableBindings.prototype.unsubscribePrivateChannel = function () {
        if (this.privateLiveChannel && this.privateLiveChannel.channel) {
            this.privateLiveChannel.channel.subscription.unsubscribe();
        }
    };

    window.PlaylistCableBindings = PlaylistCableBindings;
}(window);
