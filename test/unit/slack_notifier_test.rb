require 'test_helper'
require 'slack_notifier'

class SlackNotifierTest < Test::Unit::TestCase
  context "Slack Notifier" do
    setup do
      @slack_notifier = SlackNotifier.new
    end

    context "when created" do
      should "have no initialized properties" do
        assert_nil @slack_notifier.url
        assert_nil @slack_notifier.token
        assert_nil @slack_notifier.channel
        assert_equal false, @slack_notifier.only_failed_builds
        assert_equal false, @slack_notifier.only_fixed_and_broken_builds
        assert_equal false, @slack_notifier.only_first_failure
      end

      should "not be enabled" do
        assert_nil @slack_notifier.enabled?
      end
    end


    context "when url, token, and channel are provided" do
      setup do
        @slack_notifier.url = "https://my.slack.com"
        @slack_notifier.token = "mytoken"
        @slack_notifier.channel = "#general"

        test_url = 'http://cruisecontrolrb.org/project/test_project'
        @build = stub('Build', :successful? => false, :label => "abcdef",
                              :project => stub(
                                'Project', :name => "Test Project"),
                              :changeset => "test changeset",
                              :url => test_url)
      end


      should "generate correct slack endpoint url" do
        assert_equal "https://my.slack.com/services/hooks/slackbot?token=mytoken&channel=%23general", @slack_notifier.slack_endpoint
      end

      should "be enabled" do
        assert_not_nil @slack_notifier.enabled?
      end


      context "on successful build" do
        setup do
          @build.stubs(:successful?).returns(true)
        end

        should "notify of build outcome" do
          @slack_notifier.expects(:notify_of_build_outcome).with(
            @build, "PASSED"
          )
          @slack_notifier.build_finished(@build)
        end

        context "and only_failed_builds is true" do
          setup do
            @slack_notifier.only_failed_builds = true
          end

          should "not notify of build outcome" do
            @slack_notifier.expects(:notify_of_build_outcome).never
            @slack_notifier.build_finished(@build)
          end
        end

        context "and only_first_failure is true" do
          setup do
            @slack_notifier.only_first_failure = true
          end

          should "notify of build outcome" do
            @slack_notifier.expects(:notify_of_build_outcome).with(
              @build, "PASSED"
            )
            @slack_notifier.build_finished(@build)
          end
        end

        context "and only_fixed_and_broken_builds is true" do
          setup do
            @slack_notifier.only_fixed_and_broken_builds = true
          end

          should "not notify of build outcome" do
            @slack_notifier.expects(:notify_of_build_outcome).never
            @slack_notifier.build_finished(@build)
          end
        end

      end

      context "on failed build" do
        setup do
          @build.stubs(:successful?).returns(false)
        end

        should "notify of build outcome" do
          @slack_notifier.expects(:notify_of_build_outcome).with(
            @build, "FAILED!"
          )
          @slack_notifier.build_finished(@build)
        end

        context "and only_failed_builds is true" do
          setup do
            @slack_notifier.only_failed_builds = true
          end

          should "not notify of build outcome" do
            @slack_notifier.expects(:notify_of_build_outcome).with(
              @build,"FAILED!"
            )
            @slack_notifier.build_finished(@build)
          end
        end

        context "and only_first_failure is true" do
          setup do
            @slack_notifier.only_first_failure = true
          end

          should "not notify of build outcome" do
            @slack_notifier.expects(:notify_of_build_outcome).never
            @slack_notifier.build_finished(@build)
          end
        end

        context "and only_fixed_and_broken_builds is true" do
          setup do
            @slack_notifier.only_fixed_and_broken_builds = true
          end

          should "not notify of build outcome" do
            @slack_notifier.expects(:notify_of_build_outcome).never
            @slack_notifier.build_finished(@build)
          end
        end

      end


      context "on broken build (when previous build was success)" do
        setup do
          @previous_build = stub('Previous Build')
        end

        should "not notify of build outcome" do
          @slack_notifier.expects(:notify_of_build_outcome).never
          @slack_notifier.build_broken(@build,@previous_build)
        end

        context "and only_failed_builds is true" do
          setup do
            @slack_notifier.only_failed_builds = true
          end

          should "not notify of build outcome" do
            @slack_notifier.expects(:notify_of_build_outcome).never
            @slack_notifier.build_broken(@build,@previous_build)
          end
        end

        context "and only_first_failure is true" do
          setup do
            @slack_notifier.only_first_failure = true
          end

          should "notify of build outcome" do
            @slack_notifier.expects(:notify_of_build_outcome).with(
              @build, "BROKE!"
            )
            @slack_notifier.expects(:notify_of_build_outcome).never
            @slack_notifier.build_broken(@build,@previous_build)
          end
        end

        context "and only_fixed_and_broken_builds is true" do
          setup do
            @slack_notifier.only_fixed_and_broken_builds = true
          end

          should "notify of build outcome" do
            @slack_notifier.expects(:notify_of_build_outcome).with(
              @build, "BROKE!"
            )
            @slack_notifier.expects(:notify_of_build_outcome).never
            @slack_notifier.build_broken(@build,@previous_build)
          end
        end

      end

      context "on fixed build (when previous build was broken)" do
        setup do
          @previous_build = stub('Previous Build')
        end

        should "not notify of build outcome" do
          @slack_notifier.expects(:notify_of_build_outcome).never
          @slack_notifier.build_fixed(@build,@previous_build)
        end

        context "and only_failed_builds is true" do
          setup do
            @slack_notifier.only_failed_builds = true
          end
          should "not notify of build outcome" do
            @slack_notifier.expects(:notify_of_build_outcome).never
            @slack_notifier.build_fixed(@build,@previous_build)
          end
        end

        context "and only_first_failure is true" do
          setup do
            @slack_notifier.only_first_failure = true
          end

          should "not notify of build outcome" do
            @slack_notifier.expects(:notify_of_build_outcome).never
            @slack_notifier.build_fixed(@build,@previous_build)
          end
        end

        context "and only_fixed_and_broken_builds is true" do
          setup do
            @slack_notifier.only_fixed_and_broken_builds = true
          end

          should "notify of build outcome" do
            @slack_notifier.expects(:notify_of_build_outcome).with(
              @build, "WAS FIXED"
            )
            @slack_notifier.expects(:notify_of_build_outcome).never
            @slack_notifier.build_fixed(@build,@previous_build)
          end
        end

      end

      context "and changeset exists" do
        setup do
          changeset = <<-TXT
Build was manually requested.
Revision ...a124eaf committed by John Smith  <jsmith@company.com> on 2009-12-20 09:58:14

    made change

app/controllers/application_controller.rb |    4 ++--
1 files changed, 2 insertions(+), 2 deletions(-)
TXT
          @build = stub(
            'Build',
            :label => 'BuildLabel',
            :changeset => changeset,
            :url => 'buildurl',
            :project => stub(
              'Project',
              :name => 'ProjectName',
              :source_control => stub(
                'source control',
                :class => 'SourceControl'
              )
            )
          )
        end

        should "return changeset committers" do
          committers = @slack_notifier.get_changeset_committers(@build)
          assert_equal ["committerabc"], committers
        end

        should "send expected message to slack" do
          expected_message = %(*ProjectName build BuildLabel SUCCESSFUL*
committerabc
buildurl)
          @slack_notifier.expects(:post_to_slack!).with(expected_message)

          @slack_notifier.notify_of_build_outcome(@build, "SUCCESSFUL")
        end
      end
    end
  end
end
