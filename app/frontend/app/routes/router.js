import Vue from 'vue/dist/vue.esm'
import VueRouter from 'vue-router'
import store from "./../store/store"
import UserModel from "@models/User"
import {getCookie} from "@utils/cookies"
import eventHub from "@helpers/eventHub.js"
import RailsConfig from '@plugins/rails_config'

Vue.use(VueRouter)

const SandboxDev = () => import('@pages/SandboxDev')
const History = () => import('@pages/History')
const Blog = () => import('@pages/blog/Blog')
const Post = () => import('@pages/blog/Post')
const User = () => import('@pages/User')
const PricingPage = () => import('@pages/PricingPage')
const RestorePassword = () => import('@pages/restorePassword/RestorePassword')

let currentUser = () => {
    return store.getters["Users/currentUser"];
}
let currentGuest = () => {
    return store.getters["Users/currentGuest"];
}
let currentOrganization = () => {
    return store.getters["Users/currentOrganization"];
}

let separate = (obj, keys) => {
    let k = keys.split(".")
    let o = obj
    for(let i = 0; i < k.length; i++ ) {
      if (o) {
        o = o[k[i]]
      } else {
        o = ""
      }
    }
    return o
}

let isRouteAvailable = (to) => {
    let cu = currentUser()
    let co = currentOrganization()
    let isAvailable = true
    let requiredCredentialsAbility = to?.meta?.requiredCredentialsAbility
    let requiredCredentialsAbilityOr = to?.meta?.requiredCredentialsAbilityOr
    let requiredSubscriptionAbility = to?.meta?.requiredSubscriptionAbility
    let requiredOrganizationAbility = to?.meta?.requiredOrganizationAbility
    let requiredAuthorization = to?.meta?.requiredAuthorization

    if(requiredAuthorization) {
        if (!cu) {
            return false
        }
        isAvailable = true
    }

    if (requiredCredentialsAbility) {
        if (!cu) {
            return false
        }
        let res = true
        requiredCredentialsAbility.forEach((rca) => {
            res = res && cu?.credentialsAbility[rca]
        })
        isAvailable = isAvailable && res
    }
    if (requiredCredentialsAbilityOr) {
        if (!cu) {
            return false
        }
        let res = requiredCredentialsAbilityOr.some((rca) => {
            return cu?.credentialsAbility[rca]
        })
        isAvailable = isAvailable && res
    }
    if (requiredSubscriptionAbility) {
        if (!cu) {
            return false
        }
        let res = true
        requiredSubscriptionAbility.forEach((rsa) => {
            res = res && cu?.subscriptionAbility[rsa]
        })
        isAvailable = isAvailable && res
    }
    if (requiredOrganizationAbility) {
        if (!co) {
            return false
        }
        let res = true
        requiredOrganizationAbility.forEach((roa) => {
            res = res && co[roa]
        })
        isAvailable = isAvailable && res
    }
    if (to?.meta?.currentUserFieldsOr) {
        if (!cu) {
            return false
        }
        let checkRoles = to?.meta?.currentUserFieldsOr.some(e => cu[e.field] == e.value)
        isAvailable = isAvailable && checkRoles

        if(cu.platform_role == "platform_owner") isAvailable = true
    }
    if(to?.meta?.openByConfigGlobal) {
        isAvailable = separate(window.ConfigGlobal, to?.meta?.openByConfigGlobal)
    }

    return isAvailable
}

let humanityName = { // for Back buttons
    "blog": "Community",
    "channel-slug": "Channel",
    "manage-blog": "Manage",
    "post-slug": "Post"
}

const router = new VueRouter({
    mode: 'history',
    routes: [
        {
            path: '/',
            component: () => import('@pages/mainPage/MainPage'),
            name: "MainPage"
        },
        {
            path: '/signup',
            component: () => import('@pages/AuthPage'),
            name: "AuthPage"
        },
        {
            path: '/search',
            component: () => import('@pages/Search'),
            name: "Search"
        },
        {
            path: '/discover',
            component: () => import('@pages/mainPage/MainPage'),
            name: "Discover"
        },
        {
            path: '/sandbox',
            component: SandboxDev,
            name: "SandboxDev"
        },
        {
            path: '/history',
            component: History,
            name: "History"
        },
        // --- User
        {
            path: '/users/:slug',
            component: User,
            name: "user"
        },
        // --- Channel
        {
            path: '/channels/:id/:slug',
            component: () => import('@components/channel/Page'),
            name: "channel-slug"
        },
        // --- Blog
        {
            path: '/o/:organization/community/',
            component: Blog,
            name: "blog",
            // meta: {
            //     requiredSubscriptionAbility: [
            //         'can_manage_blog'
            //     ],
            //     requiredCredentialsAbility: [
            //         'can_manage_blog_post'
            //     ]
            // }
        },
        {
            path: '/dashboard',
            component: () => import('@components/dashboard/DashboardPage'),
            name: "dashboard",
            children: [
                {
                    path: "/dashboard/documents",
                    component: () => import('@components/documents/DashboardPage'),
                    children: [
                        {
                            path: '',
                            component: () => import('@components/documents/DashboardDocumentsContent'),
                            name: "documents"
                        }
                    ],
                    meta: {
                        requiredOrganizationAbility: [
                            'has_active_subscription_or_split_revenue'
                        ]
                    }
                },
                {
                    path: '/dashboard/user_management',
                    component: () => import('@components/roles/DashboardPage'),
                    children: [
                        {
                            path: '',
                            name: "user_management",
                            redirect: '/dashboard/user_management/users',
                        },
                        {
                            path: '/dashboard/user_management/users',
                            component: () => import('@components/roles/UsersTab'),
                            name: "users",
                            meta: {
                                requiredSubscriptionAbility: [
                                    'can_manage_team'
                                ],
                                requiredCredentialsAbility: [
                                    'can_manage_team'
                                ]
                            }
                        },
                        {
                            path: '/dashboard/user_management/roles',
                            component: () => import('@components/roles/RolesTab'),
                            name: "roles",
                            meta: {
                                requiredSubscriptionAbility: [
                                    'can_manage_team',
                                ],
                                requiredCredentialsAbility: [
                                    'can_manage_roles',
                                ]
                            }
                        },
                        {
                            path: '/dashboard/user_management/roles/:id/duplicate',
                            component: () => import('@components/roles/RolesEdit'),
                            props: {mode: 'edit'},
                            name: "roles_duplicate",
                            meta: {
                                requiredCredentialsAbility: [
                                    'can_manage_roles',
                                ]
                            }
                        },
                        {
                            path: '/dashboard/user_management/roles/new',
                            component: () => import('@components/roles/RolesEdit'),
                            props: {mode: 'new'},
                            name: "roles_new",
                            meta: {
                                requiredCredentialsAbility: [
                                    'can_manage_roles',
                                ]
                            }
                        },
                        {
                            path: '/dashboard/user_management/roles/:id',
                            component: () => import('@components/roles/RolesEdit'),
                            props: {mode: 'show'},
                            name: "roles_show",
                            meta: {
                                requiredCredentialsAbility: [
                                    'can_manage_roles',
                                ]
                            }
                        },
                        {
                            path: '/dashboard/user_management/roles/:id/edit',
                            component: () => import('@components/roles/RolesEdit'),
                            props: {mode: 'update'},
                            name: "roles_update",
                            meta: {
                                requiredCredentialsAbility: [
                                    'can_manage_roles',
                                ]
                            }
                        }
                    ]
                },
                {
                    path: "/dashboard/community",
                    component: () => import('@components/blog/DashboardPage'),
                    children: [
                        {
                            path: '',
                            name: "blog-dashboard",
                            redirect: '/dashboard/community/posts/new',
                        },
                        {
                            path: "/dashboard/community/posts/new",
                            component: () => import('@components/blog/NewPost'),
                            name: "create-post",
                            meta: {
                                requiredSubscriptionAbility: [
                                    'can_manage_blog',
                                ],
                                requiredCredentialsAbility: [
                                    'can_manage_blog_post',
                                ]
                            }
                        },
                        {
                            path: '/dashboard/community/posts',
                            component: () => import('@components/blog/ManagePost'),
                            name: "manage-blog",
                            meta: {
                                requiredSubscriptionAbility: [
                                    'can_manage_blog',
                                ],
                                requiredCredentialsAbilityOr: [
                                    'can_manage_blog_post',
                                    'can_moderate_blog_post'
                                ]
                            }
                        }
                    ]
                },
                {
                    path: "/dashboard/business_plan",
                    component: () => import('@components/business/DashboardPage'),
                    meta: {
                        openByConfigGlobal: "service_subscriptions.enabled",
                        requiredCredentialsAbility: [
                            'can_manage_business_plan'
                        ]
                    },
                    children: [
                        {
                            path: '',
                            name: "business_plan",
                            component: () => import('@pages/business/BusinessPlan'),
                            meta: {
                                openByConfigGlobal: "service_subscriptions.enabled"
                            }
                        }
                    ]
                },
                {
                    path: "/dashboard/free_subscriptions",
                    component: () => import('@components/free-subscriptions/DashboardPage'),
                    meta: {
                        requiredOrganizationAbility: [
                            'enable_free_subscriptions'
                        ]
                    },
                    children: [
                        {
                            path: '',
                            component: () => import('@components/free-subscriptions/DashboardContent'),
                            name: "free_subscriptions",
                            meta: {
                                requiredOrganizationAbility: [
                                    'enable_free_subscriptions'
                                ]
                            }
                        }
                    ]
                },
                {
                    path: "/dashboard/contacts",
                    component: () => import('@components/contacts-mailing/DashboardPage'),
                    children: [
                        {
                            path: '',
                            component: () => import('@pages/contacts-mailing/ContactsMailing'),
                            name: "contacts",
                            // meta: {
                            //     requiredOrganizationAbility: [
                            //         'has_active_subscription_or_split_revenue'
                            //     ]
                            // }
                        }
                    ]
                },
                {
                    path: "/dashboard/reviews",
                    component: () => import('@components/reviews/DashboardPage'),
                    children: [
                        {
                            path: '',
                            component: () => import('@components/reviews/DashboardContent'),
                            name: "reviews",
                            meta: {
                                requiredOrganizationAbility: [
                                    'has_active_subscription_or_split_revenue'
                                ]
                            }
                        }
                    ]
                },
                {
                    path: "/dashboard/comments",
                    component: () => import('@components/comments/DashboardPage'),
                    children: [
                        {
                            path: '',
                            component: () => import('@components/comments/DashboardContent'),
                            name: "comments",
                            meta: {
                                requiredOrganizationAbility: [
                                    'has_active_subscription_or_split_revenue'
                                ]
                            }
                        }
                    ]
                },
                {
                    path: '/dashboard/my_library',
                    component: () => import('@components/feed/DashboardPage'),
                    children: [
                        {
                            path: '',
                            component: () => import('@pages/MyFeed'),
                            name: "my_library"
                        }
                    ]
                },
                {
                    path: '/dashboard/components_builder',
                    component: () => import('@components/components_builder/DashboardPage'),
                    children: [
                        {
                            path: '',
                            component: () => import('@pages/ComponentsBuilder'),
                            name: "ComponentsBuilder"
                        }
                    ]
                },
                {
                    path: '/dashboard/optin',
                    component: () => import('@components/mops/DashboardPage'),
                    children: [
                        {
                            path: '',
                            component: () => import('@components/mops/MopsDashboard'),
                            name: "OptinManager"
                        }
                    ]
                },
                {
                    path: '/dashboard/booking',
                    component: () => import('@components/booking/DashboardPage'),
                    children: [
                        {
                            path: '',
                            component: () => import('@components/booking/BookingDashboard'),
                            name: "Booking",
                            meta: {
                                requiredAuthorization: true,
                                requiredCredentialsAbility: ['can_manage_booking']
                            }
                        }
                    ]
                },
                {
                    path: '/dashboard/polls',
                    component: () => import('@components/polls/DashboardPage'),
                    children: [
                        {
                            path: '',
                            component: () => import('@components/polls/PollsDashboard'),
                            name: "Polls",
                            meta: {
                                requiredCredentialsAbility: ['can_manage_polls']
                            }
                        }
                    ]
                }
            ]
        },
        {
            path: '/reports',
            component: () => import('@pages/ReportsPage'),
            name: "Reports",
            children: [
                {
                    path: "/reports/network_sales_reports",
                    component: () => import('@components/reports/NetworkSalesReports'),
                    name: "NetworkSalesReports",
                    meta: {
                        requiredCredentialsAbility: [
                            'can_view_revenue_report'
                        ],
                        currentUserFieldsOr: [
                            {
                                field: "platform_role",
                                value: "platform_owner"
                            },
                            {
                                field: "role",
                                value: "presenter"
                            }
                        ]
                    }
                }
            ]
        },
        {
            path: '/o/:organization/community/:slug',
            component: Post,
            name: "post-slug"
        },
        // --- Business Plans
        {
            path: '/pricing',
            component: PricingPage,
            name: "BusinessPlans",
            meta: {
                openByConfigGlobal: "service_subscriptions.enabled"
            }
        },
        {
            path: '/rooms/:id',
            component: () => import('@pages/Room'),
            name: "Room"
        },
        {
            path: '/rooms/join/:token',
            component: () => import('@pages/Room'),
            name: "JoinRoom"
        },
        {
            path: '/ome',
            component: () => import('@pages/ome/WebRTCClient'),
            name: "ome"
        },
        {
            path: '/organizations',
            component: () => import('@pages/organizations/OrganizationsPage'),
            name: "OrganizationsPage"
        },
        {
            path: '/reset_password',
            component: RestorePassword,
            name: "reset_password"
        }
    ]
});

router.beforeEach(async (to, from, next) => {
    if(to.name && window.isVueSidebar && !window.isInitRoute) {
        setTimeout(() => {
            location.href = to.fullPath
        }, 100)
    }
    window.isInitRoute = false

    eventHub.$emit('reset-priority');
    store.dispatch("Users/setPageOrganization", null)
    // let token = getCookie('_unite_session_jwt');
    // if(token){
    //   let tokenType = parseJwt(token)?.type;
    //   if(tokenType === 'room_member'){
    //     deleteCookie("_unite_session_jwt")
    //   }
    // }
    if (!currentUser() && (to.path.includes("dashboard") || to.path.includes("reports"))) {
        try { // for rejecting
            let uRes = await UserModel.api().currentUser()
            if (uRes) store.dispatch("Users/setCurrents", uRes.response.data.response)
            else eventHub.$emit("currentUser:null")
        } catch (error) {
            let refresh = getCookie('_unite_session_jwt_refresh')
            if (refresh) {
                // window.updateJWT()
                let refreshRes = await UserModel.api().getTokens({refresh})
                if (refreshRes) {
                    updateCookiesFromJwtResponse(refreshRes.response)
                    let uRes2 = await UserModel.api().currentUser()
                    if (uRes2) store.dispatch("Users/setCurrents", uRes2.response.data.response)
                    else eventHub.$emit("currentUser:null")
                }
            }
        }
    } else {
        UserModel.api().currentUser().then(res => {
            store.dispatch("Users/setCurrents", res.response.data.response)
        }).catch(err => {
            console.log(err)
            eventHub.$emit("currentUser:null")
        })
    }

    if (["post-slug", "blog"].includes(to.name)) {
        document.body.classList.add("PostPage");
    } else {
        document.body.classList.remove("PostPage");
    }

    if (to.name === 'documents' && !RailsConfig.global.is_document_management_enabled) {
        window.location.href = '/404'
        return false
    }

    if(to.name == "Booking" && !RailsConfig.global.booking?.enabled) {
        window.location.href = '/dashboard'
        return false
    }

    if (!isRouteAvailable(to)) {
        if (currentUser()) {
            window.location.href = '/dashboard'
        } else {
            window.location.href = '/'
        }
    } else {
        let hn = humanityName[to.name]
        let data = JSON.parse(JSON.stringify({
            name: to.name,
            path: to.path
        })) // deep copy; 'to' immutable
        if (hn) data["humanityName"] = hn
        store.dispatch("Global/setRouterHistory", data)
        next()
    }
})

export default router