# frozen_string_literal: true
FactoryBot.define do
  factory :user_account do
    city { 'Houston' }
    country { %w[DE UA PL].sample }
    phone { '5555555555' }
    found_us_method { FoundUsMethod.first || FactoryBot.create(:found_us_method) }
    user
  end

  factory :us_user_account, parent: :user_account do
    country { 'US' }
    country_state { 'texas' }
  end

  factory :participant_user_account, parent: :user_account do
    talent_list { nil }
  end

  factory :presenter_user_account, parent: :user_account do
    available_by_request_for_live_vod { [true, false].sample }
    talent_list do
      collection = %w[animals architecture art asia australia autumn baby band barcelona beach berlin bike bird birds birthday
                      black blackandwhite blue bw california canada canon car cat chicago china christmas church city clouds color concert dance day de dog
                      england europe fall family fashion festival film florida flower flowers food football france friends fun garden geotagged germany girl graffiti
                      green halloween hawaii holiday house india instagramapp iphone iphoneography island italia italy japan kids la lake landscape light
                      live london love macro me mexico model museum music nature new newyork newyorkcity night nikon nyc ocean old paris park party people photo
                      photography photos portrait raw red river rock san sanfrancisco scotland sea seattle show sky snow spain spring square squareformat street
                      summer sun sunset taiwan texas thailand tokyo travel tree trees trip uk unitedstates urban usa vacation vintage washington water wedding
                      white winter woman yellow zoo]
      collection.sample(3)
    end
    tagline do
      [
        'I consider my self as a hardworking and ambitious person',
        'Classical music is a major part of my life',
        'At my free time, I like solelywalks, eating ice cream, and listening to Music.',
        'I am basically a simple, adjusting and fun loving person',
        'I would describe myself as a very ambitious, hardworking and sincere girl.',
        'I am enthusiastic about taking upnew challenges in life.',
        'Friendly and joyful is what my friends would describe me as'
      ].sample
    end
    bio do
      bio1 = "I love life! Everyday is a new experience! I love to help others and enjoy laughing and watching others havea good time!
              I am a very honest person who will bust his butt to to achieve goals in life!
              I am very into natureand will pull over on the side of the road to move a turtle so it doesn't get run over.
              I like all kinds of weather (except when it is over 80 degrees) I don't like watching people get hurt and I will defend people that can'tdefend themselves!
              I don't like people who lie or are high and mighty! People who purposely hurt others arescum and should be put away forever!
              But for the most part I am a content person who believes that weshould all stop and enjoy life when ever we can because we are only here
              a short time and letting life slip bywithout enjoying it is a waste! I could go on and on but you get the idea of how I am"

      bio2 = <<HEREDOC
      Sample descriptionAll right,here's my 7 things:
      1.I'm a big fan of Avril Lavigne!The biggest kind!
      2.I love reading!My favourite classic poet is Dante Aligheri.I am also a Douglas Adams fan.
      3.I'm proud of my native city.
      4.I love movies.My favorite actors are Al Pacino and Keanu Reeves. Favorite actress will be NataliePortman.
      5.Want to be a psycologist in the future,but not sure.
      6.Wild,bad tempered,but also show kindness and peace-loving.
      7. I think life is like a comedy with a tragic ending. Since you know the ending,why not enjoy the fun partfirst?
HEREDOC

      bio3 = <<HEREDOC
      1.Im a big fan of Hannah Montana
      2.I love reading mostly baby sitters club books
      3.Im kind,caring wild,nice, funny,silly sometimes
      4. I want to be a police officer in the future
      5.My motto is be yourself
      6. My favorouite actress is Miley Cyrus
      7.I am also outgoing,loud, not afraid to tell the truth about someone
HEREDOC
      [bio1, bio2, bio3].sample[0..999].gsub(/\s\w+$/, '...')
    end
  end

  factory :aa_stub_user_accounts, parent: :user_account
end
