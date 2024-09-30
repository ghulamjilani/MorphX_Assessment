// base
import axios from '@utils/axios.js'
import Vue from 'vue/dist/vue.esm'
import Vuex from 'vuex'
import VuexORM from '@vuex-orm/core'
import VuexORMAxios from '@vuex-orm/plugin-axios'

// models
import User from '@models/User'
import Presenter from '@models/Presenter'
import Session from '@models/Session'
import Video from '@models/Video'
import Recording from '@models/Recording'
import Room from '@models/Room'
import Channel from '@models/Channel'
import Search from '@models/Search'
import Creator from '@models/Creator'
import LightSession from '@models/LightSession'
import LightVideo from '@models/LightVideo'
import VideoSource from '@models/VideoSource'
import Studio from '@models/Studio'
import StudioRoom from '@models/StudioRoom'
import Contacts from '@models/Contacts'
import Activities from '@models/Activities'
import Notification from '@models/Notification'
import Conversation from '@models/Conversation'
import Message from '@models/Message'
import NearestSession from '@models/NearestSession'
import SelfFollows from '@models/SelfFollows'
import SelfSubscription from '@models/SelfSubscription'
import SelfFreeSubscription from '@models/SelfFreeSubscription'
import UserFollowers from '@models/UserFollowers'
import CompanyFollowers from '@models/CompanyFollowers'
import UserFollows from '@models/UserFollows'
import Members from '@models/Members'
import Share from '@models/Share'
import Blog from '@models/Blog'
import GroupsMembers from '@models/GroupsMembers'
import Groups from '@models/Groups'
import OrganizationMemberships from '@models/OrganizationMemberships'
import BlogComments from '@models/BlogComments'
import BlockingNotification from '@models/BlockingNotification'
import PlanPackage from '@models/PlanPackage'
import ServiceSubscription from '@models/ServiceSubscription'
import PaymentMethod from '@models/PaymentMethod'
import PaymentTransaction from '@models/PaymentTransaction'
import Mail from '@models/Mail'
import Logs from '@models/Logs'
import Themes from '@models/Themes'
import Review from '@models/Review'
import Comments from '@models/Comments'
import Document from '@models/Document'
import Pagination from '@models/Pagination'
import ImConversations from '@models/ImConversations'
import ImConversationMessages from '@models/ImConversationMessages'
import PageBuilder from '@models/PageBuilder'
import Reports from '@models/Reports'
import Article from '@models/Article'
import Customer from '@models/Customer'
import OptIn from '@models/OptIn'
import PlatformOwner from '@models/PlatformOwner'
import Booking from '@models/Booking'
import Polls from '@models/Polls'
import Files from '@models/Files'
import Feed from '@models/Feed'

// mindbodyonline models
import MbClassDescription from '@models/mindbodyonline/MbClassDescription'
import MbClassRoom from '@models/mindbodyonline/MbClassRoom'
import MbClassSchedule from '@models/mindbodyonline/MbClassSchedule'
import MbLocation from '@models/mindbodyonline/MbLocation'
import MbSite from '@models/mindbodyonline/MbSite'
import MbStaff from '@models/mindbodyonline/MbStaff'

// Vuex Modules
import Statistics from '@modules/Statistics'
import Users from '@modules/Users'
import Global from '@modules/Global'
import VideoClient from '@modules/VideoClient'

Vue.use(Vuex)
VuexORM.use(VuexORMAxios, {axios})

const database = new VuexORM.Database()
database.register(User)
database.register(Session)
database.register(Video)
database.register(Recording)
database.register(Room)
database.register(Channel)
database.register(Presenter)
database.register(Search)
database.register(Creator)
database.register(LightSession)
database.register(LightVideo)
database.register(VideoSource)
database.register(Studio)
database.register(StudioRoom)
database.register(Contacts)
database.register(Activities)
database.register(Notification)
database.register(Conversation)
database.register(Message)
database.register(NearestSession)
database.register(SelfFollows)
database.register(SelfSubscription)
database.register(SelfFreeSubscription)
database.register(UserFollowers)
database.register(CompanyFollowers)
database.register(UserFollows)
database.register(Members)
database.register(Share)
database.register(Blog)
database.register(GroupsMembers)
database.register(Groups)
database.register(OrganizationMemberships)
database.register(BlogComments)
database.register(BlockingNotification)
database.register(PlanPackage)
database.register(ServiceSubscription)
database.register(PaymentMethod)
database.register(PaymentTransaction)
database.register(Mail)
database.register(Logs)
database.register(Themes)
database.register(Review)
database.register(Comments)
database.register(Document)
database.register(Pagination)
database.register(ImConversations)
database.register(ImConversationMessages)
database.register(PageBuilder)
database.register(Reports)
database.register(Article)
database.register(Customer)
database.register(OptIn)
database.register(PlatformOwner)
database.register(Booking)
database.register(Polls)
database.register(Files)
database.register(Feed)

database.register(MbClassDescription)
database.register(MbClassRoom)
database.register(MbClassSchedule)
database.register(MbLocation)
database.register(MbSite)
database.register(MbStaff)

const debug = process.env.NODE_ENV !== 'production'

let plagins = [VuexORM.install(database)]

let store = new Vuex.Store({
    strict: debug,
    plugins: plagins,
    state: {
        sortVideoUid: null,
        sortSessionUid: null,
        sortRecordingUid: null,

        calendarVideoUid: null,
        calendarSessionUid: null,
        calendarRecordingUid: null,

        searchList: [],
        searchLoader: true,
        searchParams: null,
        isSearchInTwoColumn: false,
        searchPagination: {
            limit: 15,
            offset: 0
        }
    },
    actions: {
        SET_SEARCH_LOADER({commit}, status) {
            commit('SET_SEARCH_LOADER', status)
        },
        UPDATE_SEARCH_PARAMS({commit}, params) {
            commit('UPDATE_SEARCH_PARAMS', params)
        },
        UPDATE_SEARCH_LIST({commit}, list) {
            commit('UPDATE_SEARCH_LIST', list)
        },
        CLEAR_SEARCH_LIST({commit}) {
            commit('CLEAR_SEARCH_LIST')
        },
        UPDATE_SEARCH_PAGINATION({commit}) {
            commit('UPDATE_SEARCH_PAGINATION')
        },
        RESET_SEARCH_PAGINATION({commit}) {
            commit('RESET_SEARCH_PAGINATION')
        },
        TOGGLE_SEARCH_GRID_ORIENTATION({commit}) {
            commit('TOGGLE_SEARCH_GRID_ORIENTATION')
        }
    },
    mutations: {
        refreshUiUid(state, payload) {
            state[payload.stateField] = uid()
        },
        UPDATE_SEARCH_LIST(state, list) {
            state.searchList = [...state.searchList, ...list]
        },
        CLEAR_SEARCH_LIST(state) {
            state.searchList = []
            Video.create({data: []})
            Channel.create({data: []})
            User.create({data: []})
            Recording.create({data: []})
            Session.create({data: []})
        },
        UPDATE_SEARCH_PAGINATION(state) {
            state.searchPagination.offset = state.searchPagination.offset + state.searchPagination.limit
        },
        RESET_SEARCH_PAGINATION(state) {
            state.searchPagination.offset = 0
        },
        UPDATE_SEARCH_PARAMS(state, params) {
            state.searchParams = params
        },
        SET_SEARCH_LOADER(state, status) {
            state.searchLoader = status
        },
        TOGGLE_SEARCH_GRID_ORIENTATION(state) {
            state.isSearchInTwoColumn = !state.isSearchInTwoColumn
        }
    },
    getters: {
        searchLoadingStatus: state => state.searchLoader,
        getSearchParams: state => state.searchParams,
        getSearchList: state => state.searchList,
        getSearchPagination: state => state.searchPagination,
        isSearchInTwoColumn: state => state.isSearchInTwoColumn,
        sortVideoUid: state => {
            return state.sortVideoUid
        },
        sortSessionUid: state => {
            return state.sortSessionUid
        },
        sortRecordingUid: state => {
            return state.sortRecordingUid
        },
        calendarVideoUid: state => {
            return state.calendarVideoUid
        },
        calendarSessionUid: state => {
            return state.calendarSessionUid
        },
        calendarRecordingUid: state => {
            return state.calendarRecordingUid
        }
    },
    modules: {
        Statistics,
        Users,
        Global,
        VideoClient
    }
})

export default store