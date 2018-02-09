defmodule Dataloader.EctoTest do
  use ExUnit.Case, async: true

  alias Dataloader.{TestRepo, User, Post}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestRepo)

    test_pid = self()
    source = Dataloader.Ecto.new(TestRepo, query: &query(&1, &2, test_pid))

    loader =
      Dataloader.new()
      |> Dataloader.add_source(Test, source)

    {:ok, loader: loader}
  end

  test "basic loading works", %{loader: loader} do
    users = [
      %{username: "Ben Wilson"}
    ]

    TestRepo.insert_all(User, users)

    users = TestRepo.all(User)
    user_ids = users |> Enum.map(& &1.id)

    loader =
      loader
      |> Dataloader.load_many(Test, User, user_ids)
      |> Dataloader.run()

    loaded_users =
      loader
      |> Dataloader.get_many(Test, User, user_ids)

    assert_receive(:querying)

    assert length(loaded_users) == 1
    assert users == loaded_users

    # loading again doesn't query again due to caching
    loader
    |> Dataloader.load_many(Test, User, user_ids)
    |> Dataloader.run()

    refute_receive(:querying)
  end

  test "successive loads query only for new info", %{loader: loader} do
    users = [
      %{username: "Ben Wilson"},
      %{username: "Andy McVitty"}
    ]

    TestRepo.insert_all(User, users)
    [user1, user2] = TestRepo.all(User)

    [post1, post2] =
      [
        %Post{user_id: user1.id},
        %Post{user_id: user2.id}
      ]
      |> Enum.map(&TestRepo.insert!/1)

    loader =
      loader
      |> Dataloader.load(Test, :user, post1)
      |> Dataloader.run()

    loaded_user =
      loader
      |> Dataloader.get(Test, :user, post1)

    assert_receive(:querying)

    assert user1 == loaded_user

    loader =
      loader
      |> Dataloader.load(Test, :user, post1)
      |> Dataloader.load(Test, :user, post2)
      |> Dataloader.run()

    assert_receive(:querying)

    loaded_user1 =
      loader
      |> Dataloader.get(Test, :user, post1)

    loaded_user2 =
      loader
      |> Dataloader.get(Test, :user, post2)

    assert user2 == loaded_user2

    assert user1 == loaded_user1
  end

  test "load same key multi times only adds to batches once", %{loader: loader} do
    loader_called_once = Dataloader.load(loader, Test, User, 1)
    loader_called_twice = Dataloader.load(loader_called_once, Test, User, 1)
    
    assert loader_called_once == loader_called_twice
  end
  
  test "association loading works", %{loader: loader} do
    user = %User{username: "Ben Wilson"} |> TestRepo.insert!()

    posts =
      [
        %Post{user_id: user.id},
        %Post{user_id: user.id}
      ]
      |> Enum.map(&TestRepo.insert!/1)

    loader =
      loader
      |> Dataloader.load(Test, :posts, user)
      |> Dataloader.run()

    loaded_posts =
      loader
      |> Dataloader.get(Test, :posts, user)

    assert posts == loaded_posts
    assert_receive(:querying)

    # loading again doesn't query again due to caching
    loader
    |> Dataloader.load(Test, :posts, user)
    |> Dataloader.run()

    refute_receive(:querying)
  end

  test "loading something from cache doesn't change the loader", %{loader: loader} do
    user = %User{username: "Ben Wilson"} |> TestRepo.insert!()

    _ =
      [
        %Post{user_id: user.id},
        %Post{user_id: user.id}
      ]
      |> Enum.map(&TestRepo.insert!/1)

    round1_loader =
      loader
      |> Dataloader.load(Test, :posts, user)
      |> Dataloader.run()

    assert ^round1_loader =
             round1_loader
             |> Dataloader.load(Test, :posts, user)
             |> Dataloader.run()

    assert loader != round1_loader
  end

  test "cache can be warmed", %{loader: loader} do
    user = %User{username: "Ben Wilson"} |> TestRepo.insert!()

    posts =
      [
        %Post{user_id: user.id},
        %Post{user_id: user.id}
      ]
      |> Enum.map(&TestRepo.insert!/1)

    loader = Dataloader.put(loader, Test, :posts, user, posts)

    loader
    |> Dataloader.load(Test, :posts, user)
    |> Dataloader.run()

    refute_receive(:querying)
  end

  test "ecto not association loaded struct doesn't warm cache", %{loader: loader} do
    user = %User{username: "Ben Wilson"} |> TestRepo.insert!()

    posts =
      [
        %Post{user_id: user.id},
        %Post{user_id: user.id}
      ]
      |> Enum.map(&TestRepo.insert!/1)

    loader = Dataloader.put(loader, Test, :posts, user, user.posts)

    loader =
      loader
      |> Dataloader.load(Test, :posts, user)
      |> Dataloader.run()

    loaded_posts =
      loader
      |> Dataloader.get(Test, :posts, user)

    assert posts == loaded_posts
    assert_receive(:querying)
  end

  defp query(queryable, _args, test_pid) do
    send(test_pid, :querying)
    queryable
  end
end
