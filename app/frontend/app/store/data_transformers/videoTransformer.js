import store from "@store/store"
import Session from "@models/Session"
import eventHub from "@helpers/eventHub"

export default {
    search({data, headers}) {
        eventHub.$emit('searchResponse', {data: data, type: 'video'})

        let formatedVideos = []
        let formatedSession = []
        if (!data.offset) {
            store.commit('refreshUiUid', {model: 'video', stateField: 'sortVideoUid', modelField: 'sortUid'})
        }

        /*
          Requested Video structure
    
          {
            id: '',
            ...,
            room: {
              id: '...',
              ...,
            }
          }
    
          With related Session
    
           {
            id: '',
            ...,
            presenter: {
              id: '',
              ...,
              user: {
                id: '',
                ...
              }
            }
          }
        */
        data.response?.videos?.forEach(item => {
            let video = item.video
            video.sortUid = store.getters.sortVideoUid
            video.room = item.room
            video.user = item.presenter_user
            formatedVideos.push(video)

            // prepare related session to insert
            let session = item.abstract_session
            session.presenter = item.presenter
            session.presenter.user = item.presenter_user
            formatedSession.push(session)
        });
        // insert related session
        Session.insertOrUpdate({data: formatedSession})

        return formatedVideos
    },

    fetch({data, headers}) {
        let formatedVideos = []
        let formatedSession = []
        if (!store.getters.calendarVideoUid) {
            store.commit('refreshUiUid', {model: 'video', stateField: 'calendarVideoUid', modelField: 'calendarUid'})
        }

        /*
          Requested Video structure
    
          {
            id: '',
            ...,
            room: {
              id: '...',
              ...,
            }
          }
    
          With related Session
    
           {
            id: '',
            ...,
            presenter: {
              id: '',
              ...,
              user: {
                id: '',
                ...
              }
            }
          }
        */
        data.response?.videos?.forEach(item => {
            let video = item.video
            video.calendarUid = store.getters.calendarVideoUid
            video.room = item.room
            video.user = item.presenter_user
            formatedVideos.push(video)

            // prepare related session to insert
            let session = item.abstract_session
            session.presenter = item.presenter
            session.presenter.user = item.presenter_user
            formatedSession.push(session)
        });
        // insert related session
        Session.insertOrUpdate({data: formatedSession})

        return formatedVideos
    }
}