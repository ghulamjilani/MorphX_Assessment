//= require templates/dashboard/share_list_modal
//= require templates/dashboard/invited_user
//= require templates/dashboard/contact_user

+function (window) {
    'use strict';
    window.ShareListModal = Backbone.View.extend({

        region: '#shareListModal',

        template: HandlebarsTemplates['dashboard/share_list_modal'],

        invitedUserTemplate: HandlebarsTemplates['dashboard/invited_user'],

        contactUserTemplate: HandlebarsTemplates['dashboard/contact_user'],

        initialize: function (options) {
            if (options == null) {
                options = {};
            }
            this.contacts = new Backbone.Collection(options.contacts);
            this.users = new Backbone.Collection(options.users || []);
            this.list_id = options.list_id;
            this.listenTo(this.contacts, 'add', this.renderContact);
            this.listenTo(this.contacts, 'change', this.renderContact);
            this.listenTo(this.users, 'add', this.renderInvited);
            this.listenTo(this.users, 'remove', this.removeInvited);
            this.listenTo(this.users, 'change', this.renderInvited);
            return this;
        },

        events: {
            'click .contactList-item .text-ellipsis': 'toggleInviteUser',
            'click .UsersWrapp .avatarImg-SD': 'removeInvitedUser',
            'change .selectAll [type=checkbox]': 'toggleSelectAll',
            'keyup .InviteByEmail': 'filterContactsList',
            'change .InviteByEmail': 'filterContactsList',
            'click .InviteByEmail-wrapp button.clear_field': 'clearInviteByEmail',
            'click .close_invite_modal': 'closeModal',
            'click .done': 'saveToForm',
            'touchend .contactList-item': 'handleTouchend'
        },

        render: function () {
            var data;
            this.mergeContacts();
            data = {
                contacts: this.contacts.toJSON(),
                url: this.url
            };
            this.setElement(this.template(data));
            $(this.region).html(this.$el);
            this.users.each(this.renderInvited, this);
            this.contacts.each(this.renderContact, this);
            this.checkNewContact();
            $(this.region).modal('show');
            return this;
        },

        renderContact: function (item) {
            var that = this;
            _.each(this.$('.tab-pane'), function (tab) {
                var $item, container, data, html;
                data = item.toJSON();
                html = that.contactUserTemplate(data);
                $item = $(tab).find(".contactList-item[data-email='" + data.email + "']");
                if ($item.length) {
                    return $item.replaceWith(html);
                } else {
                    container = data.new_contact ? '#new_contacts_list_area' : '#contacts_list_area';
                    return $(tab).find(container).append($(html));
                }
            });
            this.checkNewContact();
            this.checkInvitedUsersWrapp();
            this.checkSelectAllState();
        },

        renderInvited: function (item) {
            var $contact_item, $invited_list, email, html, state;
            this.mergeContacts();
            state = item.get('state');
            email = item.get('email');
            html = this.invitedUserTemplate(item.toJSON());
            $invited_list = state === 'co-presenter' ? this.$('.UsersWrapp.co-hosts') : this.$('.UsersWrapp.participants');
            if ($invited_list.find("[data-email='" + email + "']").length) {
                $invited_list.find("[data-email='" + email + "']").parents('.InviteViewersAndCoHosts-user').replaceWith(html);
            } else {
                $invited_list.prepend(html);
            }
            this.checkInvitedUsersWrapp();
            this.checkSelectAllState();
            $contact_item = this.$(".contactList-item[data-email='" + email + "']");
            $contact_item.addClass('active');
            if (state !== 'co-presenter' && state !== 'immersive-and-livestream') {
                $contact_item.find("[type=radio][value='" + state + "']").attr('checked', true);
            }
        },

        removeInvited: function (item) {
            var $contact_item, $invited_list, email;
            this.mergeContacts();
            email = item.get('email');
            $invited_list = item.get('state') === 'co-presenter' ? this.$('.UsersWrapp.co-hosts') : this.$('.UsersWrapp.participants');
            $invited_list.find("[data-email='" + email + "']").parent('.InviteViewersAndCoHosts-user').remove();
            this.checkInvitedUsersWrapp();
            this.checkSelectAllState();
            $contact_item = this.$(".contactList-item[data-email='" + email + "']");
            $contact_item.removeClass('active');
            $contact_item.find('input[type=radio]').attr('checked', false);
        },

        checkInvitedUsersWrapp: function () {
            return _.each(this.$('.UsersWrapp'), function (wr) {
                var no_users;
                no_users = $(wr).find('.avatarImg-SD').length < 1;
                $(wr).toggleClass('hidden', no_users);
                return $(wr).prev('.UsersWrappTitle').toggleClass('hidden', no_users);
            });
        },

        checkSelectAllState: function () {
            var all, any;
            any = this.users.length > 0;
            all = this.contacts.length === this.users.length;
            return this.$('.selectAll [type=checkbox]').attr('checked', any).toggleClass('some_selected', any && !all);
        },

        checkNewContact: function () {
            var include_new;
            include_new = this.contacts.where({
                new_contact: true
            }).length > 0;
            return this.$('.contactList-b hr').toggle(include_new);
        },

        mergeContacts: function () {
            var that = this;
            this.contacts.each(function (contact) {
                var user;
                user = that.users.findWhere({
                    email: contact.get('email')
                });
                contact.set({
                    invited: user && user.get('invited')
                });
                if (user) {
                    return user.set({
                        slug: contact.get('slug')
                    });
                }
            });
        },

        toggleSelectAll: function (e) {
            var $el, contacts_emails, invited_emails, to_invite, to_remove;
            $el = $(e.currentTarget);
            var that = this;
            if ($el.is(':checked') || $el.hasClass('some_selected')) {
                if ($el.hasClass('some_selected')) {
                    $el.attr('checked', true);
                }
                invited_emails = this.users.pluck('email');
                to_invite = this.contacts.filter(function (contact) {
                    var email;
                    email = contact.get('email');
                    return !_.contains(invited_emails, email) && that.$(".contactList-b:visible .contactList-item[data-email='" + email + "']").is(':visible');
                });
                _.each(to_invite, function (contact) {
                    return that.inviteByEmail(contact.get('email'));
                });
            } else {
                contacts_emails = this.contacts.pluck('email');
                to_remove = this.users.filter(function (user) {
                    var email;
                    email = user.get('email');
                    return _.contains(contacts_emails, email) && that.$(".contactList-b:visible .contactList-item[data-email='" + email + "']").is(':visible');
                });
                this.users.remove(to_remove);
            }
        },

        toggleInviteUser: function (e) {
            var $item, email, user;
            $item = $(e.currentTarget).parents('.contactList-item');
            email = $item.data('email');
            user = this.users.findWhere({
                email: email
            });
            if (user) {
                this.users.remove(user);
            } else {
                this.inviteByEmail(email);
            }
            $item.toggleClass('active', !user);
        },

        clearInviteByEmail: function (e) {
            var $input;
            $input = $(e.currentTarget).parents('.add_or_filter_by_email').find('input');
            $input.val('');
            $input.trigger('change');
            return false;
        },

        filterContactsList: function (e) {
            var $input, $list_items, emails, exp, matched_contacts, query, valid_email;
            $input = $(e.currentTarget).parents('.add_or_filter_by_email').find('input');
            query = $input.val();
            valid_email = this.isEmailFormatValid(query);
            $input.parents('.tab-pane').find('.add_to_contacts').attr('disabled', !valid_email).toggleClass('disabled', !valid_email);
            $list_items = this.$('.contactList:visible .contactList-item');
            if (query) {
                exp = new RegExp(query, 'i');
                matched_contacts = this.contacts.filter(function (contact) {
                    return contact.get('email').match(exp) || contact.get('display_name').match(exp);
                });
                if (matched_contacts.length) {
                    emails = _.map(matched_contacts, function (contact) {
                        return contact.get('email');
                    });
                    _($list_items).each(function (item) {
                        return $(item).toggle(_(emails).contains($(item).data('email')));
                    });
                } else {
                    $list_items.hide();
                }
                $input.parents('.tab-pane').find('.selectAll').hide();
            } else {
                $list_items.show();
                $input.parents('.tab-pane').find('.selectAll').show();
            }
        },

        isEmailFormatValid: function (email) {
            var input;
            if (!email) {
                return false;
            }
            input = document.createElement('input');
            input.type = 'email';
            input.value = email;
            input.pattern = "[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,63}$";
            return input.checkValidity();
        },

        inviteByEmail: function (email) {
            var model, user;
            if (!this.isEmailFormatValid(email)) {
                $.showFlashMessage('Invalid email format', {
                    type: 'error',
                    timeout: 3000
                });
                return false;
            } else if (this.users.findWhere({
                email: email
            })) {
                $.showFlashMessage(email + " has been already invited", {
                    type: 'error',
                    timeout: 3000
                });
                return false;
            } else {
                user = this.contacts.findWhere({
                    email: email
                });
                model = new InvitedUser({
                    id: user.id,
                    email: user.get('email'),
                    display_name: user.get('display_name'),
                    avatar_url: user.get('avatar_url'),
                    invited: true
                });
                this.users.add(model);
                return true;
            }
        },

        removeInvitedUser: function (e) {
            var $item, user;
            $item = $(e.currentTarget);
            user = this.users.findWhere({
                email: $item.data('email')
            });
            this.users.remove(user);
            $item.parent('.InviteViewersAndCoHosts-user').remove();
        },

        saveToForm: function () {
            var data, url;
            url = Routes.share_dashboard_list_path(this.list_id);
            data = _.map(this.users.models, function (u) {
                return u.id;
            });
            var that = this;
            $.ajax({
                type: 'POST',
                url: url,
                data: {
                    user_ids: data
                },
                dataType: 'json',
                beforeSend: function () {
                    return that.$('a.done, a.close_invite_modal').addClass('disabled').attr('disabled', true);
                },
                error: function (data, error) {
                    $.showFlashMessage(data.responseText || data.statusText, {
                        type: 'error'
                    });
                    return that.$('a.done, a.close_invite_modal').removeClass('disabled').attr('disabled', false);
                },
                success: function () {
                    $.showFlashMessage('List was successfully shared', {
                        type: 'success'
                    });
                    that.hideModal();
                    return that.remove();
                }
            });
        },

        usersData: function () {
            var form_data;
            if (this.users.models.length === 0) {
                return [];
            }
            form_data = new FormData;
            _(this.users.models).each(function (item, i) {
                return form_data.append.apply(form_data, ["users[" + i + "][id]", item.id]);
            });
            return form_data;
        },

        closeModal: function () {
            return this.remove();
        },

        showModal: function () {
            return $(this.region).modal('show');
        },

        hideModal: function () {
            return $(this.region).modal('hide');
        },

        handleTouchend: function () {
            return true;
        },
    })
}(window);
