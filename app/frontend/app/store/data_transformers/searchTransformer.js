import store from "@store/store"
import Video from "@models/Video"
import User from "@models/User"
import Session from "@models/Session"
import Channel from "@models/Channel"
import Recording from '@models/Recording'
import Article from '@models/Article'
import eventHub from "@helpers/eventHub"

export default {
    search({data, headers, newPage}) {
        eventHub.$emit('searchResponse', {data: data, type: 'search'})
        let formatedSearch = data.response.documents
        let videoArray = []
        let sessionArray = []
        let channelArray = []
        let userArray = []
        let recordingArray = []
        let articlesArray = []
        formatedSearch.forEach((item) => {
            switch (item.document.searchable_type) {
                case 'Video':
                    videoArray.push(item)
                    break;
                case 'Session':
                    sessionArray.push(item)
                    break;
                case 'Channel':
                    channelArray.push(item)
                    break;
                case 'User':
                    userArray.push(item)
                    break;
                case 'Recording':
                    recordingArray.push(item)
                    break;
                case 'Blog::Post':
                    articlesArray.push(item)
                    break;
            }
        })

        if (videoArray.length) {
            let formatedVideos = videoArray.map(function (item) {
                return {
                    room: item.searchable_model.room,
                    user: item.searchable_model.presenter_user,
                    type: item.document.searchable_type,
                    organization: item.searchable_model.organization,
                    channel: item.searchable_model.channel,
                    abstract_session: item.searchable_model.abstract_session,
                    total_views_count: item.document.views_count,
                    ...item.searchable_model.video
                }
            })
            let formatedSessions = videoArray.map(function (item) {
                return {
                    user: item.searchable_model.presenter_user,
                    type: 'Session',
                    organization: item.searchable_model.organization,
                    total_views_count: item.document.views_count,
                    ...item.searchable_model.abstract_session
                }
            })
            Session.insertOrUpdate({data: formatedSessions})
            Video.insertOrUpdate({data: formatedVideos})
        }

        if (userArray.length) {
            let formatedUsers = userArray.map(function (item) {
                return {
                    type: item.document.searchable_type,
                    ...item.searchable_model.user
                }
            })
            User.insertOrUpdate({data: formatedUsers})
        }

        if (recordingArray.length) {
            let formatedRecordings = recordingArray.map(function (item) {
                return {
                    user: item.searchable_model.organizer,
                    type: item.document.searchable_type,
                    organization: item.searchable_model.organization,
                    channel: item.searchable_model.channel,
                    total_views_count: item.document.views_count,
                    ...item.searchable_model.recording
                }
            })
            Recording.insertOrUpdate({data: formatedRecordings})
        }

        if (sessionArray.length) {
            let formatedSessions = sessionArray.map(function (item) {
                return {
                    user: item.searchable_model.presenter_user,
                    type: item.document.searchable_type,
                    organization: item.searchable_model.organization,
                    channel: item.searchable_model.channel,
                    total_views_count: item.document.views_count,
                    ...item.searchable_model.session
                }
            })
            Session.insertOrUpdate({data: formatedSessions})
        }

        if (channelArray.length) {
            let formatedChannels = channelArray.map(function (item) {
                return {
                    user: item.searchable_model.user,
                    type: item.searchable_type,
                    channel_category: item.searchable_model.channel_category,
                    ...item.searchable_model.channel
                }
            })
            Channel.insertOrUpdate({data: formatedChannels})
        }

        if (articlesArray.length) {
            let formatedArticles = articlesArray.map(function (item) {
                return {
                    type: item.document.searchable_type,
                    ...item.searchable_model.post
                }
            })
            Article.insertOrUpdate({data: formatedArticles})
        }

        const mappedSearch = formatedSearch.map(function (item) {
            return {
                id: item.document.searchable_id,
                type: item.document.searchable_type,
            }
        })
        if (mappedSearch) {
            store.dispatch('UPDATE_SEARCH_LIST', mappedSearch)
        }
        return formatedSearch
    }
}