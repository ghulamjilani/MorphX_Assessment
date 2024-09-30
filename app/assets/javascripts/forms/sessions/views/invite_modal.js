(function () {

    window.InviteModal = Backbone.View.extend({
        region: '#InviteViewersAndCoHosts',

        template: HandlebarsTemplates['sessions/form/invite_modal'],

        invitedUserTemplate: HandlebarsTemplates['sessions/invite_modal/invited_user'],

        contactUserTemplate: HandlebarsTemplates['sessions/invite_modal/contact_user'],

        initialize: function (options) {
            if (options == null) {
                options = {}
            }
            $(this.region).modal({
                backdrop: 'static',
                keyboard: false,
                show: false
            })
            if (window.session_form_fields) {
                this.session = window.session_form_fields.model
            }
            this.contacts = options.contacts
            this.users = options.users
            if (this.session) {
                this.livestream = this.session.get('livestream')
                this.immersive = this.session.get('immersive')
                this.co_host = this.session.get('co_hosts')
            } else {
                this.livestream = options.livestream
                this.immersive = options.immersive
                this.co_host = options.co_hosts
            }
            this.immersive_and_livestream = this.livestream && this.immersive
            this.role_selection = !this.immersive_and_livestream
            this.url = options.url
            this.listenTo(this.contacts, 'add', this.renderContact)
            this.listenTo(this.contacts, 'change', this.renderContact)
            this.listenTo(this.users, 'add', this.renderInvited)
            this.listenTo(this.users, 'remove', this.removeInvited)
            this.listenTo(this.users, 'change', this.renderInvited)
            if (this.session) {
                this.listenTo(this.session, 'change:livestream', this.typeChanged)
                this.listenTo(this.session, 'change:immersive', this.typeChanged)
                this.listenTo(this.session, 'change:co_hosts', this.coHostChanged)
            }
            return this
        },

        events: {
            'change input[name=link_as_viewer_and_guest]': 'toggleLinkStates',
            'change .contactList-item .radio input': 'toggleByState',
            'click .contactList-item .text-ellipsis': 'toggleInviteUser',
            'click .UsersWrapp .avatarImg-SD': 'removeInvitedUser',
            'change .selectAll [type=checkbox]': 'toggleSelectAll',
            'keyup .InviteByEmail': 'filterContactsList',
            'change .InviteByEmail': 'filterContactsList',
            'keydown .InviteByEmail': 'addToContactsAndInvite',
            'click .add_to_contacts': 'addToContactsAndInvite',
            'click .InviteByEmail-wrapp button.clear_field': 'clearInviteByEmail',
            'click .close_invite_modal': 'closeModal',
            'click .done': 'saveToForm',
            'touchend .contactList-item': 'handleTouchend'
        },

        render: function () {
            var data
            data = {
                livestream: this.livestream,
                immersive: this.immersive,
                co_host: this.co_host,
                immersive_and_livestream: this.immersive_and_livestream,
                role_selection: this.role_selection,
                default_state: this.getState(),
                contacts: this.contacts.toJSON(),
                url: this.url
            }
            data.co_host_tab = this.$('#section-Co-Hosts').hasClass('active')
            this.setElement(this.template(data))
            $(this.region).html(this.$el)
            let that = this
            this.contacts.fetch().then(function () {
                that.mergeContacts()
                that.renderUsers()
                that.renderContacts()
                that.checkNewContact()
                that.infinityLoader()
            })
            return this
        },
        renderUsers: function() {
            this.users.each(this.renderInvited, this)
        },
        renderContacts: function() {
            this.contacts.each(this.renderContact, this)
        },
        checkLimit: function () {
            if ($('.UsersWrapp').children().length > 300 && $('.unobtrusive-flash-container').children().length == 1) {
                $.showFlashMessage('A large number of invited users increases the session start time. More than 300 users can increase the session start time by more than 5 minutes.', {
                    type: 'error',
                    timeout: 10000
                })
            }
        },

        infinityLoader: function () {
            var listElm = document.querySelector('.contactList-b')
            window.contacts = this.contacts
            listElm.addEventListener('scroll', () => {
                if (listElm.scrollTop + listElm.clientHeight + 20 >= listElm.scrollHeight) {
                    if (this.contacts.total > this.contacts.length) {
                        this.fetch()
                    }
                }
            })
        },

        fetch: function () {
            let url = Routes.api_v1_user_contacts_path() + '?' + $.param({limit: 50, offset: this.contacts.length})
            $.ajax({
                beforeSend: function (xhr) {
                    var token = getCookie('_unite_session_jwt')
                    xhr.setRequestHeader('Authorization', ("Basic ".concat(token)))
                },
                type: 'GET',
                url: url,
                dataType: 'json',
                contentType: 'application/json',
                success: (data) => {
                    data.response.forEach(model => {
                        model.display_name = model.contact_user ? model.contact_user.public_display_name : model.name
                        model.avatar_url = model.contact_user ? model.contact_user.avatar_url : model.avatar_url
                        this.contacts.add(model)
                    })
                }
            })
        },

        renderContact: function (item) {
            this.mergeContacts()
            if (!item.get('email') || typeof(this.$) == 'undefined') {
                return
            }
            _.each(this.$('.tab-pane'), (function (_this) {
                return function (tab) {
                    var $item, container, data, html
                    data = item.toJSON()
                    if ($(tab).data('type') === 'participant') {
                        data.role_selection = _this.role_selection
                        data.immersive_and_livestream = _this.immersive_and_livestream
                    }
                    html = _this.contactUserTemplate(data)
                    $item = $(tab).find(".contactList-item[data-email='" + data.email + "']")
                    if ($item.length) {
                        return $item.replaceWith(html)
                    } else {
                        container = data.new_contact ? '#new_contacts_list_area' : '#contacts_list_area'
                        return $(tab).find(container).append($(html))
                    }
                }
            })(this))
            this.checkNewContact()
            this.checkInvitedUsersWrapp()
            this.checkSelectAllState()
        },

        renderInvited: function (item) {
            this.checkLimit()
            let $contact_item, $invited_list, email, html, state;
            this.mergeContacts()
            state = item.get('state')
            email = item.get('email')
            html = this.invitedUserTemplate(item.toJSON())
            $invited_list = state === 'co-presenter' ? this.$('.UsersWrapp.co-hosts') : this.$('.UsersWrapp.participants')
            if ($invited_list.find("[data-email='" + email + "']").length) {
                $invited_list.find("[data-email='" + email + "']").parents('.InviteViewersAndCoHosts-user').replaceWith(html)
            } else {
                $invited_list.prepend(html)
            }
            this.checkInvitedUsersWrapp()
            this.checkSelectAllState()
            $contact_item = this.$(".contactList-item[data-email='" + email + "']")
            $contact_item.addClass('active')
            if (state !== 'co-presenter' && state !== 'immersive-and-livestream') {
                $contact_item.find("[type=radio][value='" + state + "']").attr('checked', true)
            }
        },

        removeInvited: function (item) {
            var $contact_item, $invited_list, email
            this.mergeContacts()
            email = item.get('email')
            $invited_list = item.get('state') === 'co-presenter' ? this.$('.UsersWrapp.co-hosts') : this.$('.UsersWrapp.participants')
            $invited_list.find("[data-email='" + email + "']").parent('.InviteViewersAndCoHosts-user').remove()
            this.checkInvitedUsersWrapp()
            this.checkSelectAllState()
            $contact_item = this.$(".contactList-item[data-email='" + email + "']")
            $contact_item.removeClass('active')
            $contact_item.find('input[type=radio]').attr('checked', false)
        },

        checkInvitedUsersWrapp: function () {
            return _.each(this.$('.UsersWrapp'), function (wr) {
                var no_users
                no_users = $(wr).find('.avatarImg-SD').length < 1
                $(wr).toggleClass('hidden', no_users)
                return $(wr).prev('.UsersWrappTitle').toggleClass('hidden', no_users)
            })
        },

        checkSelectAllState: function () {
            var all, any
            any = this.users.length > 0
            all = this.contacts.length === this.users.length
            return this.$('.selectAll [type=checkbox]').attr('checked', any).toggleClass('some_selected', any && !all)
        },

        checkNewContact: function () {
            var include_new
            include_new = this.contacts.where({
                new_contact: true
            }).length > 0
            return this.$('.contactList-b hr').toggle(include_new)
        },

        mergeContacts: function () {
            this.contacts.each((function (_this) {
                return function (contact) {
                    var user
                    user = _this.users.findWhere({
                        email: contact.get('email')
                    })
                    contact.set({
                        state: user && user.get('state')
                    })
                    contact.set({
                        status: user && user.get('status')
                    })
                    if (user) {
                        return user.set({
                            slug: contact.get('slug')
                        })
                    }
                }
            })(this))
        },

        toggleSelectAll: async function (e) {
            var $el, contacts_emails, invited_emails, to_invite, to_remove
            $el = $(e.currentTarget)
            $(this.$el).find('.wait').show()
            await new Promise(r => setTimeout(r, 100))
            if ($el.is(':checked') || $el.hasClass('some_selected')) {
                if ($el.hasClass('some_selected')) {
                    $el.prop('checked', true)
                }
                invited_emails = this.users.pluck('email')
                to_invite = this.contacts.filter((function (_this) {
                    return function (contact) {
                        var email
                        email = contact.get('email')
                        return !_.contains(invited_emails, email) && contact.get('status') !== 'accepted' && contact.get('state') !== 'co-presenter' && _this.$(".contactList-b:visible .contactList-item[data-email='" + email + "']").is(':visible')
                    }
                })(this))
                _.each(to_invite, (function (_this) {
                    return async function (contact) {
                        return _this.inviteByEmail(contact.get('email'), _this.getState())
                    }
                })(this))
            } else {
                contacts_emails = this.contacts.pluck('email')
                to_remove = this.users.filter((function (_this) {
                    return function (user) {
                        var email
                        email = user.get('email')
                        return _.contains(contacts_emails, email) && user.get('status') !== 'accepted' && user.get('state') !== 'co-presenter' && _this.$(".contactList-b:visible .contactList-item[data-email='" + email + "']").is(':visible')
                    }
                })(this))
                this.users.remove(to_remove)
            }
            $(this.$el).find('.wait').hide()
        },

        toggleInviteUser: function (e) {
            var $item, email, state, user
            $item = $(e.currentTarget).parents('.contactList-item')
            email = $item.data('email')
            state = $item.parents('.tab-pane').data('type')
            if (state === 'participant') {
                state = this.getState()
            }
            user = this.users.findWhere({
                email: email
            })
            if (user && user.get('status') !== 'accepted') {
                this.users.remove(user)
            } else {
                this.inviteByEmail(email, state)
            }
            $item.toggleClass('active', !user)
        },

        clearInviteByEmail: function (e) {
            var $input
            $input = $(e.currentTarget).parents('.add_or_filter_by_email').find('input')
            $input.val('')
            $input.trigger('change')
            return false
        },

        addToContactsAndInvite: function (e) {
            var $input, query, valid_email
            $input = $(e.currentTarget).parents('.add_or_filter_by_email').find('input')
            query = $input.val()
            valid_email = this.isEmailFormatValid(query)
            if (e.type === 'click' || e.keyCode === 13 && e.type === 'keydown') {
                e.preventDefault()
                e.stopPropagation()
                if (e.keyCode === 13 && !valid_email) {
                    return false
                }
                if (this.inviteByEmail(query, $input.data('state'))) {
                    $input.val('')
                    $input.trigger('change')
                }
                return false
            }
        },

        filterContactsList: function (e) {
            var $input, $list_items, emails, exp, matched_contacts, query, valid_email
            $input = $(e.currentTarget).parents('.add_or_filter_by_email').find('input')
            query = $input.val()
            valid_email = this.isEmailFormatValid(query)
            $input.parents('.tab-pane').find('.add_to_contacts').attr('disabled', !valid_email).toggleClass('disabled', !valid_email)
            $list_items = this.$('.contactList:visible .contactList-item')
            if (query) {
                exp = new RegExp(query, 'i')
                matched_contacts = this.contacts.filter(function (contact) {
                    return contact.get('email').match(exp) || contact.get('display_name').match(exp)
                })
                if (matched_contacts.length) {
                    emails = _.map(matched_contacts, function (contact) {
                        return contact.get('email')
                    })
                    _($list_items).each(function (item) {
                        return $(item).toggle(_(emails).contains($(item).data('email')))
                    })
                } else {
                    $list_items.hide()
                }
                $input.parents('.tab-pane').find('.selectAll').hide()
            } else {
                $list_items.show()
                $input.parents('.tab-pane').find('.selectAll').show()
            }
        },

        isEmailFormatValid: function (email) {
            var input
            if (!email) {
                return false
            }
            input = document.createElement('input')
            input.type = 'email'
            input.value = email
            input.pattern = "[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,63}$"
            return input.checkValidity()
        },

        inviteByEmail: async function (email, state) {
            await new Promise(r => setTimeout(r, 50))
            var info, model
            if (!this.isEmailFormatValid(email)) {
                $.showFlashMessage('Invalid email format', {
                    type: 'error',
                    timeout: 3000
                })
                return false
            } else if (this.users.findWhere({
                email: email
            })) {
                $.showFlashMessage(email + " has been already invited", {
                    type: 'error',
                    timeout: 3000
                })
                return false
            } else {
                info = extractAttributesFromContactsByEmail(this.contacts.toJSON(), email)
                model = new InvitedUser({
                    email: email,
                    display_name: info.display_name,
                    avatar_url: info.avatar_url,
                    state: state,
                    add_as_contact: info.add_as_contact || true
                })
                if (this.contacts.where({
                    email: email
                }).length === 0) {
                    model.set({ new_contact: true })
                    this.contacts.add(model.attributes)
                }
                this.users.add(model)
                return true
            }
        },

        removeInvitedUser: function (e) {
            var $item, user
            $item = $(e.currentTarget)
            user = this.users.findWhere({
                email: $item.data('email')
            })
            this.users.remove(user)
            $item.parent('.InviteViewersAndCoHosts-user').remove()
        },

        toggleLinkStates: function (e) {
            var $container, invited_users, state
            if (!this.immersive_and_livestream) {
                return
            }
            this.role_selection = e.currentTarget.checked
            $container = $(e.currentTarget).parents('.contactList').find('.contactList-b')
            state = this.getState()
            this.$('.InviteByEmail:visible').data('state', state)
            $container.find('.selectAll').toggleClass('disabled', this.role_selection)
            $container.find('.selectAll > [type=checkbox]').attr('disabled', this.role_selection)
            $container.find('.title_viewer, .title_guest, .state_selector').toggleClass('hidden', !this.role_selection)
            invited_users = this.users.filter(function (user) {
                return user.get('state') !== 'co-presenter' && user.get('status').toLowerCase() === 'pending'
            })
            _.each(invited_users, function (user) {
                return user.set({
                    state: state
                })
            })
        },

        toggleByState: function (e) {
            var $item, email, state, user
            if (!this.immersive_and_livestream) {
                return
            }
            $item = $(e.currentTarget)
            email = $item.parents('.contactList-item').data('email')
            user = this.users.findWhere({
                email: email
            })
            state = $item.val()
            if (user && state) {
                user.set({
                    state: state
                })
            } else if (state) {
                this.inviteByEmail(email, state)
            } else if (user) {
                this.users.remove(user)
            }
        },

        typeChanged: function (item) {
            var invited_users, state, states
            this.livestream = item.get('livestream')
            this.immersive = item.get('immersive')
            this.immersive_and_livestream = this.livestream && this.immersive
            this.role_selection = !this.immersive_and_livestream
            state = this.getState()
            states = [null, void 0]
            if (this.immersive_and_livestream || this.livestream && !this.immersive) {
                states.push('immersive')
            }
            if (this.immersive_and_livestream || this.immersive && !this.livestream) {
                states.push('livestream')
            }
            if (!this.immersive_and_livestream) {
                states.push('immersive-and-livestream')
            }
            invited_users = this.users.filter(function (user) {
                return user.get('status') === 'pending' && _.contains(states, user.get('state'))
            })
            _.each(invited_users, function (user) {
                return user.set({
                    state: state
                })
            })
            return this.saveToForm()
        },

        coHostChanged: function (item) {
            this.co_host = item.get('co_hosts')
            if (!this.co_host) {
                this.users.remove(this.users.where({
                    state: 'co-presenter'
                }))
            }
            return this.saveToForm()
        },

        getState: function () {
            if (this.immersive_and_livestream && !this.role_selection) {
                return 'immersive-and-livestream'
            } else if (this.livestream) {
                return 'livestream'
            } else if (this.immersive) {
                return 'immersive'
            }
        },

        saveToForm: function () {
            if (this.url) {
                return $.ajax({
                    type: 'POST',
                    url: this.url,
                    data: 'invited_users_attributes=' + encodeURIComponent(JSON.stringify(this.users)),
                    beforeSend: (function (_this) {
                        return function () {
                            return _this.$('a.done, a.close_invite_modal').addClass('disabled').attr('disabled', true)
                        }
                    })(this),
                    error: (function (_this) {
                        return function (data, error) {
                            $.showFlashMessage(data.responseText || data.statusText, {
                                type: 'error'
                            })
                            return _this.$('a.done, a.close_invite_modal').removeClass('disabled').attr('disabled', false)
                        }
                    })(this),
                    success: (function (_this) {
                        return function () {
                            _this.hideModal()
                            return _this.remove()
                        }
                    })(this)
                })
            } else {
                window.session_form_fields.setInvitedUsersAttributes(this.users)
            }
        },

        closeModal: function () {
            if (this.url) {
                return $(this.region).one('hidden.bs.modal', (function (_this) {
                    return function () {
                        return _this.remove()
                    }
                })(this))
            } else {
                this.saveToForm()
            }
        },

        showModal: function () {
            $(this.region).modal('show')
        },

        hideModal: function () {
            $(this.region).modal('hide')
        },

        handleTouchend: function () {
            return true
        }
    })

}).call(this)
