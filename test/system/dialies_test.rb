require "application_system_test_case"

class DialiesTest < ApplicationSystemTestCase
  setup do
    @dialy = dialies(:one)
  end

  test "visiting the index" do
    visit dialies_url
    assert_selector "h1", text: "Dialies"
  end

  test "should create dialy" do
    visit dialies_url
    click_on "New dialy"

    fill_in "Date", with: @dialy.date
    fill_in "Text", with: @dialy.text
    fill_in "Title", with: @dialy.title
    click_on "Create Dialy"

    assert_text "Dialy was successfully created"
    click_on "Back"
  end

  test "should update Dialy" do
    visit dialy_url(@dialy)
    click_on "Edit this dialy", match: :first

    fill_in "Date", with: @dialy.date
    fill_in "Text", with: @dialy.text
    fill_in "Title", with: @dialy.title
    click_on "Update Dialy"

    assert_text "Dialy was successfully updated"
    click_on "Back"
  end

  test "should destroy Dialy" do
    visit dialy_url(@dialy)
    click_on "Destroy this dialy", match: :first

    assert_text "Dialy was successfully destroyed"
  end
end
