defmodule Carrier.External.SlackAPI.FormatTest do
  use ExUnit.Case, async: true
  alias Carrier.External.SlackAPI.Format

  describe "html_to_mrkdwn/1" do
    test "with html" do
      html =
        ~S(<div>Trix is an <strong>open-source</strong> project from <a href="https://basecamp.com/">Basecamp</a>, the creators of <del>Ruby on Rails</del>. Millions of people trust their text to <em>Basecamp </em>and<br>we built Trix to give them the best possible editing experience.</div><div><br></div><pre>ㅁㄴㅇㄹ</pre><div><br></div><ul><li>1st</li><li>2nd</li></ul><div><br></div><ol><li>1st</li><li>2nd</li></ol>)

      assert Format.html_to_mrkdwn(html) ==
               "Trix is an *open-source* project from <https://basecamp.com/|Basecamp>, the creators of ~Ruby on Rails~. Millions of people trust their text to _Basecamp_ and\nwe built Trix to give them the best possible editing experience.\n\n```ㅁㄴㅇㄹ```\n• 1st\n• 2nd\n\n"
    end

    test "with wired line break" do
      html =
        ~S(<div><strong>🟢 비강남서초/경기 강남언니가 먹는다! 🟢<br></strong><br>지금 바로 지역확장 지표를 확인해보세요! @channel <em><br><br></em>🏥 병원별 지표 🏥 를 확인하고 싶다면?</div>)

      assert Format.html_to_mrkdwn(html) ==
               "*🟢 비강남서초/경기 강남언니가 먹는다! 🟢*\n\n지금 바로 지역확장 지표를 확인해보세요! @channel __\n\n🏥 병원별 지표 🏥 를 확인하고 싶다면?\n"
    end
  end
end
