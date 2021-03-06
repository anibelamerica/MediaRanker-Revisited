require 'test_helper'

describe WorksController do

  describe 'logged in users' do

    describe "root" do
      it "succeeds with all media types" do
        # Precondition: there is at least one media of each category
        get root_path

        must_respond_with :success

      end

      it "succeeds with one media type absent" do
        # Precondition: there is at least one media in two of the categories
        movie = works(:movie)
        movie.destroy

        expect(Work.find_by(category: 'movie')).must_be_nil

        get root_path
        must_respond_with :success
      end

      it "succeeds with no media" do
        all_work_count = Work.count

        expect {
          Work.destroy_all
        }.must_change('Work.count', -all_work_count)

        get root_path
        must_respond_with :success
      end
    end

    CATEGORIES = %w(albums books movies)
    INVALID_CATEGORIES = ["nope", "42", "", "  ", "albumstrailingtext"]

    describe "index" do

      it "succeeds when there are works" do
        user = User.first
        perform_login(user)
        expect(Work.count).must_be :>=, 1, "No works are set up in fixtures"

        get works_path
        must_respond_with :success
      end

      it "succeeds when there are no works" do
        user = User.first
        perform_login(user)
        all_work_count = Work.count

        expect {
          Work.destroy_all
        }.must_change('Work.count', -all_work_count)

        get works_path
        must_respond_with :success
      end
    end

    describe "new" do

      it "succeeds" do
        user = User.first
        perform_login(user)
        get new_work_path

        must_respond_with :success
      end
    end

    describe "create" do

      it "creates a work with valid data for a real category" do
        user = User.first
        perform_login(user)

        CATEGORIES.each do |category|
          work_data = {
            work: {
              title: "Test Title",
              category: category.singularize
            }
          }

          test_work = Work.new(work_data[:work])
          test_work.must_be :valid?, "Work data was invalid. Engineer, please fix this."

          expect {
            post works_path, params: work_data
          }.must_change('Work.count', +1)

          must_redirect_to work_path(Work.last)

          expect(Work.last.title).must_equal work_data[:work][:title]
          expect(Work.last.category).must_equal work_data[:work][:category]
        end
      end

      it "renders bad_request and does not update the DB for bogus data" do
        user = User.first
        perform_login(user)

        CATEGORIES.each do |category|
          work_data = {
            work: {
              title: nil,
              category: category
            }
          }

          test_work = Work.new(work_data[:work])
          test_work.wont_be :valid?, "Work data was NOT invalid. Engineer, please fix this."

          expect {
            post works_path, params: work_data
          }.wont_change('Work.count')

          must_respond_with :bad_request
        end

      end

      it "renders 400 bad_request for bogus categories" do
        user = User.first
        perform_login(user)

        INVALID_CATEGORIES.each do |category|
          work_data = {
            work: {
              title: "Test Title",
              category: category
            }
          }

          test_work = Work.new(work_data[:work])
          test_work.wont_be :valid?, "Work data was NOT invalid. Engineer, please fix this."

          expect {
            post works_path, params: work_data
          }.wont_change('Work.count')

          must_respond_with :bad_request
        end
      end

    end

    describe "show" do

      let(:existing_work) { Work.first }

      it "succeeds for an extant work ID" do
        user = User.first
        perform_login(user)
        get work_path(existing_work)

        must_respond_with :success
      end

      it "renders 404 not_found for a bogus work ID" do
        user = User.first
        perform_login(user)
        id = existing_work.id
        existing_work.destroy

        get work_path(existing_work)

        must_respond_with 404
      end
    end

    describe "edit" do

      before do
        @user = User.first
        perform_login(@user)
        @save = controller.session[:user_id]
      end

      let(:existing_work) { Work.first }

      it "succeeds for an extant work ID" do
        get edit_work_path(existing_work)

        must_respond_with :success
      end

      it "renders 404 not_found for a bogus work ID" do
        id = existing_work.id
        existing_work.destroy

        get edit_work_path(existing_work)

        must_respond_with 404
      end
    end

    describe "update" do

      before do
        @user = User.first
        perform_login(@user)
        @save = controller.session[:user_id]
      end

      let(:work_data) {
        {
          work: {
            title: 'Fake Title',
            category: CATEGORIES[0].singularize
          }
        }
      }

      let(:work_test) {
        Work.new(work_data[:work])
      }

      let(:existing_work) {Work.first}
      let(:existing_id) { existing_work.id }

      it "succeeds for valid data and an extant work ID" do
        work_test.must_be :valid?, "Work data was invalid. Engineer, please fix this test."

        expect {
          patch work_path(existing_id), params: work_data
        }.wont_change('Work.count')

        must_respond_with :redirect
        must_redirect_to work_path(existing_id)

        work = Work.find_by(id: existing_id)
        expect(work.title).must_equal work_data[:work][:title]
        expect(work.category).must_equal work_data[:work][:category]

      end

      it "renders bad_request for bogus data" do
        original_work_title = Work.first.title
        work_data[:work][:title] = nil

        work_test.wont_be :valid?, "Work data was NOT invalid. Engineer, please fix this test."

        expect {
          patch work_path(existing_id), params: work_data
        }.wont_change('Work.count')

        must_respond_with :bad_request

        work = Work.find_by(id: existing_id)
        expect(work.title).must_equal original_work_title
      end

      it "renders 404 not_found for a bogus work ID" do
        id = 0

        expect {
          patch work_path(0), params: work_data
        }.wont_change('Work.count')

        must_respond_with 404
      end
    end

    describe "destroy" do

      before do
        @user = User.first
        perform_login(@user)
        @save = controller.session[:user_id]
      end

      let(:before_work_count) { Work.count }

      it "succeeds for an extant work ID" do
        work = Work.first

        expect{
          delete work_path(work)
        }.must_change('Work.count', -1)

        must_respond_with :redirect
        must_redirect_to root_path
      end

      it "renders 404 not_found and does not update the DB for a bogus work ID" do

        expect{
          delete work_path(0)
        }.wont_change('Work.count')

        must_respond_with :not_found
      end
    end
  end

  describe 'guest users' do

    describe "root" do
      it "succeeds with all media types" do
        # Precondition: there is at least one media of each category
        get root_path

        must_respond_with :success

      end

      it "succeeds with one media type absent" do
        # Precondition: there is at least one media in two of the categories
        movie = works(:movie)
        movie.destroy

        expect(Work.find_by(category: 'movie')).must_be_nil

        get root_path
        must_respond_with :success
      end

      it "succeeds with no media" do
        all_work_count = Work.count

        expect {
          Work.destroy_all
        }.must_change('Work.count', -all_work_count)

        get root_path
        must_respond_with :success
      end
    end

    CATEGORIES = %w(albums books movies)
    INVALID_CATEGORIES = ["nope", "42", "", "  ", "albumstrailingtext"]

    describe "index" do
      it "redirects to the root path when there are works" do
        expect(Work.count).must_be :>=, 1, "No works are set up in fixtures"

        get works_path
        expect(flash[:status]).must_equal :failure
        must_redirect_to root_path
      end

      it "redirects to the root path when there are no works" do
        all_work_count = Work.count

        expect {
          Work.destroy_all
        }.must_change('Work.count', -all_work_count)

        get works_path

        expect(flash[:status]).must_equal :failure
        must_redirect_to root_path
      end
    end

    describe "new" do
      it "redirects to the root path" do
        get new_work_path

        expect(flash[:status]).must_equal :failure
        must_redirect_to root_path
      end
    end

    describe "create" do
      it "redirects to the root path when attempting to create a work with valid data for a real category" do

        CATEGORIES.each do |category|
          work_data = {
            work: {
              title: "Test Title",
              category: category.singularize
            }
          }

          test_work = Work.new(work_data[:work])
          test_work.must_be :valid?, "Work data was invalid. Engineer, please fix this."

          expect {
            post works_path, params: work_data
          }.wont_change('Work.count')

          must_redirect_to root_path
          expect(flash[:status]).must_equal :failure
        end
      end

      it "redirects to the root path and does not update the DB for bogus data" do

        CATEGORIES.each do |category|
          work_data = {
            work: {
              title: nil,
              category: category
            }
          }

          test_work = Work.new(work_data[:work])
          test_work.wont_be :valid?, "Work data was NOT invalid. Engineer, please fix this."

          expect {
            post works_path, params: work_data
          }.wont_change('Work.count')

          must_redirect_to root_path
          expect(flash[:status]).must_equal :failure
          expect(flash[:result_text]).must_equal "Must be logged in to create a work."
        end

      end

      it "redirects to the root path for bogus categories" do
        INVALID_CATEGORIES.each do |category|
          work_data = {
            work: {
              title: "Test Title",
              category: category
            }
          }

          test_work = Work.new(work_data[:work])
          test_work.wont_be :valid?, "Work data was NOT invalid. Engineer, please fix this."

          expect {
            post works_path, params: work_data
          }.wont_change('Work.count')

          must_redirect_to root_path
          expect(flash[:status]).must_equal :failure
          expect(flash[:result_text]).must_equal "Must be logged in to create a work."
        end
      end

    end

    describe "show" do

      let(:existing_work) { Work.first }

      it "redirects to the root path for an extant work ID" do
        get work_path(existing_work.id)

        must_redirect_to root_path
        expect(flash[:status]).must_equal :failure
        expect(flash[:result_text]).must_equal "Must be logged in to view page."
      end

      it "redirects to the root path for a bogus work ID" do
        id = existing_work.id
        existing_work.destroy

        get work_path(existing_work.id)

        must_respond_with 404
      end
    end

    describe "edit" do

      let(:existing_work) { Work.first }

      it "redirects to the root path for an extant work ID" do
        get edit_work_path(existing_work)

        must_redirect_to root_path
        expect(flash[:status]).must_equal :failure
        expect(flash[:result_text]).must_equal "Must be logged in to edit work."
      end

      it "renders 404 not_found for a bogus work ID" do
        id = existing_work.id
        existing_work.destroy

        get edit_work_path(existing_work)

        must_respond_with 404
      end
    end

    describe "update" do

      let(:work_data) {
        {
          work: {
            title: 'Fake Title',
            category: CATEGORIES[0].singularize
          }
        }
      }

      let(:work_test) {
        Work.new(work_data[:work])
      }

      let(:existing_work) {Work.first}
      let(:existing_id) { existing_work.id }

      it "redirects to the root_path for valid data and an extant work ID" do
        work_test.must_be :valid?, "Work data was invalid. Engineer, please fix this test."

        expect {
          patch work_path(existing_id), params: work_data
        }.wont_change('Work.count')

        must_redirect_to root_path
        expect(flash[:status]).must_equal :failure
        expect(flash[:result_text]).must_equal "Must be logged in to update work."

      end

      it "redirects to the root_path for bogus data" do
        work_data[:work][:title] = nil

        work_test.wont_be :valid?, "Work data was NOT invalid. Engineer, please fix this test."

        expect {
          patch work_path(existing_id), params: work_data
        }.wont_change('Work.count')

        must_redirect_to root_path
        expect(flash[:status]).must_equal :failure
        expect(flash[:result_text]).must_equal "Must be logged in to update work."
      end

      it "redirects to the root_path for a bogus work ID" do

        expect {
          patch work_path(Work.last.id + 1), params: work_data
        }.wont_change('Work.count')

        must_respond_with 404
      end
    end

    describe "destroy" do

      let(:before_work_count) { Work.count }

      it "redirects to the root_path for an extant work ID" do
        work = Work.first

        expect{
          delete work_path(work)
        }.wont_change('Work.count')

        must_redirect_to root_path
        expect(flash[:status]).must_equal :failure
        expect(flash[:result_text]).must_equal "Must be logged in to delete a work."
      end

      it "redirects to the root_path and does not update the DB for a bogus work ID" do

        expect{
          delete work_path(0)
        }.wont_change('Work.count')

        must_respond_with 404
      end
    end
  end

  describe "upvote" do

    let(:user) { users(:grace) }

    let(:login) {
      user = users(:grace)
      perform_login(user)
    }

    it "redirects to the work page if no user is logged in" do

      work = Work.first

      post upvote_path(work)

      must_redirect_to work_path(work)
      expect(flash[:result_text]).must_equal "You must log in to do that"

    end

    it "redirects to the work page after the user has logged out" do
      login
      expect(session[:user_id]).must_equal user.id
      delete logout_path
      expect(session[:user_id]).must_equal nil

      work = Work.first

      post upvote_path(work)

      must_redirect_to work_path(work)
      expect(flash[:result_text]).must_equal "You must log in to do that"

    end

    it "succeeds for a logged-in user and a fresh user-vote pair" do
      login

      work = Work.first

      post upvote_path(work)

      must_redirect_to work_path(work)
      expect(flash[:status]).must_equal :success
    end

    it "redirects to the work page if the user has already voted for that work" do
      login
      work = Work.first
      post upvote_path(work)
      expect(flash[:status]).must_equal :success

      post upvote_path(work)

      must_redirect_to work_path(work)
      expect(flash[:result_text]).must_equal "Could not upvote"

    end
  end

end
