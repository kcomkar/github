require 'spec_helper'

describe Github::PullRequests, :type => :base do

  let(:pull_request_id) { 1 }

  describe "#pull_requests" do
    context 'check aliases' do
      it { github.pull_requests.should respond_to :pulls }
      it { github.pull_requests.should respond_to :requests }
    end

    context 'resource found' do
      let(:params) { { :state => 'closed', :unrelated => true } }

      before do
        stub_get("/repos/#{user}/#{repo}/pulls").
          with(:query => params.except(:unrelated)).
          to_return(:body => fixture('pull_requests/pull_requests.json'),
            :status => 200,
            :headers => {:content_type => "application/json; charset=utf-8"})
      end

      it "throws error if gist id not provided" do
        expect { github.pull_requests.pull_requests nil}.to raise_error(ArgumentError)
      end

      it "should get the resources" do
        github.pull_requests.pull_requests user, repo, params
        a_get("/repos/#{user}/#{repo}/pulls").with(:query => params).should have_been_made
      end

      it "should return array of resources" do
        pull_requests = github.pull_requests.pull_requests user, repo, params
        pull_requests.should be_an Array
        pull_requests.should have(1).items
      end

      it "should be a mash type" do
        pull_requests = github.pull_requests.pull_requests user, repo, params
        pull_requests.first.should be_a Hashie::Mash
      end

      it "should get pull request information" do
        pull_requests = github.pull_requests.pull_requests user, repo, params
        pull_requests.first.title.should == 'new-feature'
      end

      it "should yield to a block" do
        github.pull_requests.should_receive(:pull_requests).with(user, repo).
          and_yield('web')
        github.pull_requests.pull_requests(user, repo) { |param| 'web' }
      end
    end

    context 'resource not found' do
      before do
        stub_get("/repos/#{user}/#{repo}/pulls").
          to_return(:body => "", :status => [404, "Not Found"])
      end

      it "should return 404 with a message 'Not Found'" do
        expect {
          github.pull_requests.pull_requests user, repo
        }.to raise_error(Github::ResourceNotFound)
      end
    end
  end # pull_requests

  describe "#pull_request" do
    context 'check aliases' do
      it { github.pull_requests.should respond_to :pull_request }
      it { github.pull_requests.should respond_to :get_pull_request }
    end

    context 'resource found' do
      before do
        stub_get("/repos/#{user}/#{repo}/pulls/#{pull_request_id}").
          to_return(:body => fixture('pull_requests/pull_request.json'),
          :status => 200,
          :headers => {:content_type => "application/json; charset=utf-8"})
      end

      it "should fail to get resource without pull_request id" do
        expect { github.pull_requests.pull_request nil }.to raise_error(ArgumentError)
      end

      it "should get the resource" do
        github.pull_requests.pull_request user, repo, pull_request_id
        a_get("/repos/#{user}/#{repo}/pulls/#{pull_request_id}").
          should have_been_made
      end

      it "should get pull_request information" do
        pull_request = github.pull_requests.pull_request user, repo, pull_request_id
        pull_request.number.should eq pull_request_id
        pull_request.head.user.login.should == 'octocat'
      end

      it "should return mash" do
        pull_request = github.pull_requests.pull_request user, repo, pull_request_id
        pull_request.should be_a Hashie::Mash
      end
    end

    context 'resource not found' do
      before do
        stub_get("/repos/#{user}/#{repo}/pulls/#{pull_request_id}").
          to_return(:body => fixture('pull_requests/pull_request.json'),
            :status => 404,
            :headers => {:content_type => "application/json; charset=utf-8"})
      end

      it "should fail to retrive resource" do
        expect {
          github.pull_requests.pull_request user, repo, pull_request_id
        }.to raise_error(Github::ResourceNotFound)
      end
    end
  end # pull_request

  describe "create_request" do
    let(:inputs) {
      {
       "title" => "Amazing new feature",
       "body" => "Please pull this in!",
       "head" => "octocat:new-feature",
       "base" => "master",
       "state" => "open",
       'unrelated' => 'giberrish'
      }
    }

    context "resouce created" do
      before do
        stub_post("/repos/#{user}/#{repo}/pulls").
          with(:body => JSON.generate(inputs.except('unrelated'))).
          to_return(:body => fixture('pull_requests/pull_request.json'), :status => 201, :headers => {:content_type => "application/json; charset=utf-8"})
      end

      it "should create resource successfully" do
        github.pull_requests.create_request user, repo, inputs
        a_post("/repos/#{user}/#{repo}/pulls").with(inputs).should have_been_made
      end

      it "should return the resource" do
        pull_request = github.pull_requests.create_request user, repo, inputs
        pull_request.should be_a Hashie::Mash
      end

      it "should get the request information" do
        pull_request = github.pull_requests.create_request user, repo, inputs
        pull_request.title.should eql "new-feature"
      end
    end

    context "failed to create resource" do
      before do
        stub_post("/repos/#{user}/#{repo}/pulls").with(inputs).
          to_return(:body => fixture('pull_requests/pull_request.json'), :status => 404, :headers => {:content_type => "application/json; charset=utf-8"})

      end

      it "should faile to retrieve resource" do
        expect {
          github.pull_requests.create_request user, repo, inputs
        }.to raise_error(Github::ResourceNotFound)
      end
    end
  end # create_request

  describe "#update_request" do
    let(:inputs) {
      {
        "title" => "new title",
        "body" => "updated body",
        "state" => "open",
        "unrelated" => true
      }
    }

    context "resouce updateed" do
      before do
        stub_patch("/repos/#{user}/#{repo}/pulls/#{pull_request_id}").
          with(:body => JSON.generate(inputs.except('unrelated'))).
          to_return(:body => fixture('pull_requests/pull_request.json'),
                :status => 201,
                :headers => {:content_type => "application/json; charset=utf-8"})
      end

      it "should create resource successfully" do
        github.pull_requests.update_request user, repo, pull_request_id, inputs
        a_patch("/repos/#{user}/#{repo}/pulls/#{pull_request_id}").with(inputs).
          should have_been_made
      end

      it "should return the resource" do
        pull_request = github.pull_requests.update_request user, repo,
                                                         pull_request_id, inputs
        pull_request.should be_a Hashie::Mash
      end

      it "should get the pull_request information" do
        pull_request = github.pull_requests.update_request user, repo,
                                                        pull_request_id, inputs
        pull_request.title.should == 'new-feature'
      end
    end

    context "failed to create resource" do
      before do
        stub_patch("/repos/#{user}/#{repo}/pulls/#{pull_request_id}").
          with(inputs).
          to_return(:body => fixture('pull_requests/pull_request.json'),
            :status => 404,
            :headers => {:content_type => "application/json; charset=utf-8"})
      end

      it "should faile to retrieve resource" do
        expect {
          github.pull_requests.update_request user, repo, pull_request_id, inputs
        }.to raise_error(Github::ResourceNotFound)
      end
    end
  end # update_request

end # Github::PullRequests