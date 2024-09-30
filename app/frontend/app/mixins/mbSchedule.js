import MbClassSchedule from '@models/mindbodyonline/MbClassSchedule'
import LightSession from '@models/LightSession'
import LightVideo from '@models/LightVideo'

import utils from '@helpers/utils'

export default {
    props: ['isActive', 'sizeMode'],
    watch: {
        isActive(val) {
            if (val) {
                this.emitNewDisplayDate()
            }
        }
    },
    methods: {
        getClasses(day) {
            return MbClassSchedule.query()
                .where((mbcs) => {
                    return (day.isBetween(mbcs.start_date, mbcs.end_date, undefined, '[]'))
                        && this.isDayScheduled(mbcs, day)
                })
                .with('class_description')
                .with('location')
                .with('staff')
                .get()
        },
        getUniteSesions(day) {
            let dayFormated = day.format('YYYY-MM-DD')
            return LightSession.query()
                .where((session) => {
                    return session.start_at.split('T')[0] == dayFormated
                })
                .orderBy('start_at')
                .get()
        },
        getUniteVideo(day) {
            let dayFormated = day.format('YYYY-MM-DD')
            return LightVideo.query()
                .where((video) => {
                    return video.start_at.split('T')[0] == dayFormated
                })
                .orderBy('start_at')
                .get()
        },
        getScheduleItems(day) {
            // let mbClasses = this.getClasses(day)
            let uniteSessins = this.getUniteSesions(day)
            let uniteVideos = this.getUniteVideo(day)

            return [...uniteVideos, ...uniteSessins]
            // return [...uniteVideos, ...uniteSessins, ...mbClasses]
        },
        isDayScheduled(mbcs, day) {
            let dayName = day.format('ddd')
            if (mbcs.day_monday && dayName === 'Mon') {
                return true
            }
            if (mbcs.day_tuesday && dayName === 'Tue') {
                return true
            }
            if (mbcs.day_wednesday && dayName === 'Wed') {
                return true
            }
            if (mbcs.day_thursday && dayName === 'Thu') {
                return true
            }
            if (mbcs.day_friday && dayName === 'Fri') {
                return true
            }
            if (mbcs.day_saturday && dayName === 'Sat') {
                return true
            }
            if (mbcs.day_sunday && dayName === 'Sun') {
                return true
            }
            return false
        },
        isToday(day) {
            return utils.dateToTimeZone(moment(), true).isSame(day, 'day')
        }
    }
}