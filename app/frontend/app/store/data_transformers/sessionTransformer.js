import store from "@store/store"
import eventHub from "@helpers/eventHub"

export default {
    search({data, headers}) {
        eventHub.$emit('searchResponse', {data: data, type: 'session'})

        let formatedSessions = []
        if (!data.offset) {
            store.commit('refreshUiUid', {model: 'session', stateField: 'sortSessionUid', modelField: 'sortUid'})
        }

        /*
          Requested Session structure
          
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

        data.response?.sessions?.forEach(item => {
            let session = item.session
            session.sortUid = store.getters.sortSessionUid
            session.presenter = item.presenter
            session.presenter.user = item.presenter_user
            formatedSessions.push(session)
        });

        return formatedSessions
    },
    fetch({data, headers}) {
        let formatedSessions = []
        if (!store.getters.calendarSessionUid) {
            store.commit('refreshUiUid', {
                model: 'session',
                stateField: 'calendarSessionUid',
                modelField: 'calendarUid'
            })
        }

        /*
          Requested Session structure
          
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

        data.response?.sessions?.forEach(item => {
            let session = item.session
            session.calendarUid = store.getters.calendarSessionUid
            session.presenter = item.presenter
            session.presenter.user = item.presenter_user
            formatedSessions.push(session)
        });

        return formatedSessions
    }
}