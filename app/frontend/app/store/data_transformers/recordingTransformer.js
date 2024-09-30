import store from "@store/store"
import eventHub from "@helpers/eventHub"

export default {
    search({data, headers}) {
        eventHub.$emit('searchResponse', {data: data, type: 'recording'})

        let formatedRecordings = []
        if (!data.offset) {
            store.commit('refreshUiUid', {model: 'recording', stateField: 'sortRecordingUid', modelField: 'sortUid'})
        }

        /*
          Requested Recording structure
          
          {
            id: '',
            ...,
            channel: {
              id: '',
              ...,
              organizer: { // <-- user 
                id: '',
                ...
              }
            }
          }
        */

        data.response?.recordings?.forEach(item => {
            let recording = item.recording
            recording.sortUid = store.getters.sortRecordingUid
            recording.channel = item.channel
            recording.channel.organizer = item.organizer

            formatedRecordings.push(recording)
        });

        return formatedRecordings
    }
}