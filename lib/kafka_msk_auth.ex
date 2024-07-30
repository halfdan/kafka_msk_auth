defmodule KafkaMskAuth do
  @moduledoc """
  Documentation for `KafkaMskAuth`.
  """

  require Logger


  def adapt_auth_config(%{access_key_id: _, secret_access_key: _} = config), do: {:ok, config}

  def adapt_auth_config(%{role_arn: role_arn, web_identity_token_file: token_file}) do
    web_identity_token = File.read!(token_file)

    query = ExAws.STS.assume_role_with_web_identity(role_arn, "default", web_identity_token)

    case ExAws.request(query) do
      {:ok, %{body: config}} -> {:ok, config}
      {:error, _} -> {:error, :unable_to_assume_role_with_web_identity}
    end
  end

  def adapt_auth_config(%{role_arn: role_arn}) do
    query = ExAws.STS.assume_role(role_arn, "default")

    case ExAws.request(query) do
      {:ok, %{body: config}} -> {:ok, config}
      {:error, _} -> {:error, :unable_to_assume_role}
    end
  end
end
