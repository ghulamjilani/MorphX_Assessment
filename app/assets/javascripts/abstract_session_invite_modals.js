//= require_self
//= require session_invite_participant_modal

(function () {
    var getGravatar, md5,
        extend = function (child, parent) {
            for (var key in parent) {
                if (hasProp.call(parent, key)) child[key] = parent[key];
            }

            function ctor() {
                this.constructor = child;
            }

            ctor.prototype = parent.prototype;
            child.prototype = new ctor();
            child.__super__ = parent.prototype;
            return child;
        },
        hasProp = {}.hasOwnProperty,
        bind = function (fn, me) {
            return function () {
                return fn.apply(me, arguments);
            };
        };

    window.InfiniteStack = function (array) {
        this.array = array;
        return this.index = -1;
    };

    window.InfiniteStack.prototype = {
        nextAfter: function (value) {
            this.index = this.array.indexOf(value);
            if (this.index === (this.array.length - 1)) {
                this.index = 0;
            } else {
                this.index = this.index + 1;
            }
            return this.array[this.index];
        }
    };

    window.InvitedUser = (function (superClass) {
        extend(InvitedUser, superClass);

        function InvitedUser() {
            return InvitedUser.__super__.constructor.apply(this, arguments);
        }

        InvitedUser.prototype.defaults = {
            slug: null,
            status: 'pending',
            avatar_url: '/gender/newHidden.svg'
        };

        InvitedUser.prototype.initialize = function (options) {
            if (options == null) {
                options = {};
            }
            InvitedUser.__super__.initialize.apply(this, arguments);
            if (typeof (this.get('display_name')) === 'undefined' && typeof (this.get('email')) !== 'undefined') {
                return this.set('display_name', this.get('email'));
            }
        };

        InvitedUser.prototype.toJSON = function () {
            var data;
            data = InvitedUser.__super__.toJSON.apply(this, arguments);
            data.cid = this.cid;
            data.formatted_state = data.state === 'livestream' ? 'Viewer' : data.state === 'immersive' ? 'Guest' : data.state === 'immersive-and-livestream' ? 'Viewer and Guest' : data.state === 'co-presenter' ? 'Co-Host' : void 0;
            data.status = data.status === 'pending' ? 'Pending' : data.status === 'accepted' ? 'Accepted' : data.status === 'rejected' ? 'Declined' : void 0;
            return data;
        };

        return InvitedUser;

    })(Backbone.Model);

    window.InvitedUserCollection = Backbone.Collection.extend({
        model: InvitedUser,
        limit: 50,
        offset: 0,
        // url: function () {
        //     return this.baseUrl + '?' + $.param({limit: this.limit, offset: this.offset});
        // },
        initialize: function () {
            // this.baseUrl = Routes.dashboard_replays_path(this.channel_id);
        },

        all: function () {
            return this.models;
        }
    });

    window.ContactUser = (function (superClass) {
        extend(ContactUser, superClass);

        function ContactUser() {
            return ContactUser.__super__.constructor.apply(this, arguments);
        }

        ContactUser.prototype.defaults = {
            new_contact: false
        };

        ContactUser.prototype.toJSON = function () {
            var data;
            data = ContactUser.__super__.toJSON.apply(this, arguments);
            data.cid = this.cid;
            return data;
        };

        return ContactUser;

    })(Backbone.Model);

    window.ContactUserCollection = Backbone.Collection.extend({
        model: ContactUser,
        limit: 50,
        offset: 0,
        url: function () {
            return this.baseUrl + '?' + $.param({limit: this.limit, offset: this.offset});
        },
        initialize: function (models, options) {
            if(options) {
                this.limit = options.limit
                this.offset = options.offset
            }
            this.baseUrl = Routes.api_v1_user_contacts_path(this.channel_id);
            // this.fetch();
        },
        fetch: function (options) {
            typeof (options) != 'undefined' || (options = {});
            var that = this;
            var success = options.success;
            options.success = function (resp) {
                if (success) {
                    success(that, resp);
                }
            };
            options.beforeSend = function (xhr) {
                var token = getCookie('_unite_session_jwt');
                xhr.setRequestHeader('Authorization', ("Basic ".concat(token)));
            }
            return Backbone.Collection.prototype.fetch.call(this, options);
        },
        parse: function (resp) {
            this.offset = resp.pagination.offset;
            this.limit = resp.pagination.limit;
            this.total = resp.pagination.count;
            return resp.response.map(function(el){
                return {
                    id: el['contact_user'] && el['contact_user']['id'],
                    email: el['contact_user'] && el['contact_user']['email'] || el['email'],
                    display_name: el['contact_user'] && el['contact_user']['public_display_name'] || el['name'],
                    public_display_name: el['contact_user'] && el['contact_user']['public_display_name'] || el['name'],
                    avatar_url: el['avatar_url'],
                    slug: el['contact_user'] && el['contact_user']['relative_path']
                }
            });
        },
        all: function () {
            return this.models;
        },
    });

    $(document).on('keypress', 'form #invited_participants_new_input', function (event) {
        if (event.keyCode === 13) {
            $('.invite_btn:visible').click();
            return event.preventDefault();
        }
    });

    window.extractAttributesFromContactsByEmail = function (contacts, email) {
        var avatar_url, contactValue, display_name, obj;
        obj = _.find(contacts, function (e) {
            return e.email === email;
        });
        if (obj) {
            contactValue = false;
            avatar_url = obj.avatar_url;
            display_name = obj.display_name;
            if (typeof avatar_url === 'undefined' || avatar_url.length < 4) {
                throw new Error('can not extract avatar_url from contacts');
            }
        } else {
            contactValue = true;
            avatar_url = getGravatar(email);
        }
        return {
            add_as_contact: contactValue,
            avatar_url: avatar_url,
            display_name: display_name
        };
    };

    md5 = function (s) {
        var A, B, C, D, E, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, e, f, g, h, i, j, l, m, n, o, p, q, r, t, u,
            v, w, y, z;
        C = Array();
        P = void 0;
        h = void 0;
        E = void 0;
        v = void 0;
        g = void 0;
        Y = void 0;
        X = void 0;
        W = void 0;
        V = void 0;
        S = 7;
        Q = 12;
        N = 17;
        M = 22;
        A = 5;
        z = 9;
        y = 14;
        w = 20;
        o = 4;
        m = 11;
        l = 16;
        j = 23;
        U = 6;
        T = 10;
        R = 15;
        O = 21;
        L = function (k, d) {
            return k << d | k >>> 32 - d;
        };
        K = function (G, k) {
            var F, H, I, d, x;
            I = void 0;
            d = void 0;
            F = void 0;
            H = void 0;
            x = void 0;
            F = G & 2147483648;
            H = k & 2147483648;
            I = G & 1073741824;
            d = k & 1073741824;
            x = (G & 1073741823) + (k & 1073741823);
            if (I & d) {
                return x ^ 2147483648 ^ F ^ H;
            }
            if (I | d) {
                if (x & 1073741824) {
                    return x ^ 3221225472 ^ F ^ H;
                } else {
                    return x ^ 1073741824 ^ F ^ H;
                }
            } else {
                return x ^ F ^ H;
            }
        };
        r = function (d, F, k) {
            return d & F | ~d & k;
        };
        q = function (d, F, k) {
            return d & k | F & ~k;
        };
        p = function (d, F, k) {
            return d ^ F ^ k;
        };
        n = function (d, F, k) {
            return F ^ (d | ~k);
        };
        u = function (G, F, aa, Z, k, H, I) {
            G = K(G, K(K(r(F, aa, Z), k), I));
            return K(L(G, H), F);
        };
        f = function (G, F, aa, Z, k, H, I) {
            G = K(G, K(K(q(F, aa, Z), k), I));
            return K(L(G, H), F);
        };
        D = function (G, F, aa, Z, k, H, I) {
            G = K(G, K(K(p(F, aa, Z), k), I));
            return K(L(G, H), F);
        };
        t = function (G, F, aa, Z, k, H, I) {
            G = K(G, K(K(n(F, aa, Z), k), I));
            return K(L(G, H), F);
        };
        e = function (G) {
            var F, H, I, Z, aa, d, k, x;
            Z = void 0;
            F = G.length;
            x = F + 8;
            k = (x - (x % 64)) / 64;
            I = (k + 1) * 16;
            aa = Array(I - 1);
            d = 0;
            H = 0;
            while (H < F) {
                Z = (H - (H % 4)) / 4;
                d = H % 4 * 8;
                aa[Z] = aa[Z] | G.charCodeAt(H) << d;
                H++;
            }
            Z = (H - (H % 4)) / 4;
            d = H % 4 * 8;
            aa[Z] = aa[Z] | 128 << d;
            aa[I - 2] = F << 3;
            aa[I - 1] = F >>> 29;
            return aa;
        };
        B = function (x) {
            var F, G, d, k;
            k = '';
            F = '';
            G = void 0;
            d = void 0;
            d = 0;
            while (d <= 3) {
                G = x >>> d * 8 & 255;
                F = '0' + G.toString(16);
                k = k + F.substr(F.length - 2, 2);
                d++;
            }
            return k;
        };
        J = function (k) {
            var F, d, x;
            k = k.replace(/rn/g, 'n');
            d = '';
            F = 0;
            while (F < k.length) {
                x = k.charCodeAt(F);
                if (x < 128) {
                    d += String.fromCharCode(x);
                } else {
                    if (x > 127 && x < 2048) {
                        d += String.fromCharCode(x >> 6 | 192);
                        d += String.fromCharCode(x & 63 | 128);
                    } else {
                        d += String.fromCharCode(x >> 12 | 224);
                        d += String.fromCharCode(x >> 6 & 63 | 128);
                        d += String.fromCharCode(x & 63 | 128);
                    }
                }
                F++;
            }
            return d;
        };
        s = J(s);
        C = e(s);
        Y = 1732584193;
        X = 4023233417;
        W = 2562383102;
        V = 271733878;
        P = 0;
        while (P < C.length) {
            h = Y;
            E = X;
            v = W;
            g = V;
            Y = u(Y, X, W, V, C[P + 0], S, 3614090360);
            V = u(V, Y, X, W, C[P + 1], Q, 3905402710);
            W = u(W, V, Y, X, C[P + 2], N, 606105819);
            X = u(X, W, V, Y, C[P + 3], M, 3250441966);
            Y = u(Y, X, W, V, C[P + 4], S, 4118548399);
            V = u(V, Y, X, W, C[P + 5], Q, 1200080426);
            W = u(W, V, Y, X, C[P + 6], N, 2821735955);
            X = u(X, W, V, Y, C[P + 7], M, 4249261313);
            Y = u(Y, X, W, V, C[P + 8], S, 1770035416);
            V = u(V, Y, X, W, C[P + 9], Q, 2336552879);
            W = u(W, V, Y, X, C[P + 10], N, 4294925233);
            X = u(X, W, V, Y, C[P + 11], M, 2304563134);
            Y = u(Y, X, W, V, C[P + 12], S, 1804603682);
            V = u(V, Y, X, W, C[P + 13], Q, 4254626195);
            W = u(W, V, Y, X, C[P + 14], N, 2792965006);
            X = u(X, W, V, Y, C[P + 15], M, 1236535329);
            Y = f(Y, X, W, V, C[P + 1], A, 4129170786);
            V = f(V, Y, X, W, C[P + 6], z, 3225465664);
            W = f(W, V, Y, X, C[P + 11], y, 643717713);
            X = f(X, W, V, Y, C[P + 0], w, 3921069994);
            Y = f(Y, X, W, V, C[P + 5], A, 3593408605);
            V = f(V, Y, X, W, C[P + 10], z, 38016083);
            W = f(W, V, Y, X, C[P + 15], y, 3634488961);
            X = f(X, W, V, Y, C[P + 4], w, 3889429448);
            Y = f(Y, X, W, V, C[P + 9], A, 568446438);
            V = f(V, Y, X, W, C[P + 14], z, 3275163606);
            W = f(W, V, Y, X, C[P + 3], y, 4107603335);
            X = f(X, W, V, Y, C[P + 8], w, 1163531501);
            Y = f(Y, X, W, V, C[P + 13], A, 2850285829);
            V = f(V, Y, X, W, C[P + 2], z, 4243563512);
            W = f(W, V, Y, X, C[P + 7], y, 1735328473);
            X = f(X, W, V, Y, C[P + 12], w, 2368359562);
            Y = D(Y, X, W, V, C[P + 5], o, 4294588738);
            V = D(V, Y, X, W, C[P + 8], m, 2272392833);
            W = D(W, V, Y, X, C[P + 11], l, 1839030562);
            X = D(X, W, V, Y, C[P + 14], j, 4259657740);
            Y = D(Y, X, W, V, C[P + 1], o, 2763975236);
            V = D(V, Y, X, W, C[P + 4], m, 1272893353);
            W = D(W, V, Y, X, C[P + 7], l, 4139469664);
            X = D(X, W, V, Y, C[P + 10], j, 3200236656);
            Y = D(Y, X, W, V, C[P + 13], o, 681279174);
            V = D(V, Y, X, W, C[P + 0], m, 3936430074);
            W = D(W, V, Y, X, C[P + 3], l, 3572445317);
            X = D(X, W, V, Y, C[P + 6], j, 76029189);
            Y = D(Y, X, W, V, C[P + 9], o, 3654602809);
            V = D(V, Y, X, W, C[P + 12], m, 3873151461);
            W = D(W, V, Y, X, C[P + 15], l, 530742520);
            X = D(X, W, V, Y, C[P + 2], j, 3299628645);
            Y = t(Y, X, W, V, C[P + 0], U, 4096336452);
            V = t(V, Y, X, W, C[P + 7], T, 1126891415);
            W = t(W, V, Y, X, C[P + 14], R, 2878612391);
            X = t(X, W, V, Y, C[P + 5], O, 4237533241);
            Y = t(Y, X, W, V, C[P + 12], U, 1700485571);
            V = t(V, Y, X, W, C[P + 3], T, 2399980690);
            W = t(W, V, Y, X, C[P + 10], R, 4293915773);
            X = t(X, W, V, Y, C[P + 1], O, 2240044497);
            Y = t(Y, X, W, V, C[P + 8], U, 1873313359);
            V = t(V, Y, X, W, C[P + 15], T, 4264355552);
            W = t(W, V, Y, X, C[P + 6], R, 2734768916);
            X = t(X, W, V, Y, C[P + 13], O, 1309151649);
            Y = t(Y, X, W, V, C[P + 4], U, 4149444226);
            V = t(V, Y, X, W, C[P + 11], T, 3174756917);
            W = t(W, V, Y, X, C[P + 2], R, 718787259);
            X = t(X, W, V, Y, C[P + 9], O, 3951481745);
            Y = K(Y, h);
            X = K(X, E);
            W = K(W, v);
            V = K(V, g);
            P += 16;
        }
        i = B(Y) + B(X) + B(W) + B(V);
        return i.toLowerCase();
    };

    getGravatar = function (email, size) {
        if (size == null) {
            size = 80;
        }
        return 'http://www.gravatar.com/avatar/' + md5(email) + '.jpg?s=' + size;
    };

}).call(this);
