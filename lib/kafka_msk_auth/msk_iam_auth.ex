defmodule KafkaMskAuth.MskIamAuth do
  @moduledoc """
  SASL AWS_MSK_IAM auth backend implementation for brod Erlang library.
  To authenticate, supply aws_secret_key_id and aws_secret_access_key with access to MSK cluster
  """
  @behaviour :kpro_auth_backend

  require Logger

  @kpro_lib Application.compile_env(:kafka_msk_auth, :kpro_lib, KafkaMskAuth.KafkaProtocolLib)
  @signed_payload_generator Application.compile_env(
                              :kafka_msk_auth,
                              :signed_payload_generator,
                              KafkaMskAuth.SignedPayloadGenerator
                            )

  @handshake_version 1

  # The following code is based on the implmentation of SASL handshake implementation from kafka_protocol Erlang library
  # Ref: https://github.com/kafka4beam/kafka_protocol/blob/master/src/kpro_sasl.erl
  @impl true
  @spec auth(any(), port(), :gen_tcp | :ssl, binary(), :infinity | non_neg_integer(), {:AWS_MSK_IAM, map()}) ::
          :ok | {:error, any()}
  def auth(host, sock, mod, client_id, timeout, {:AWS_MSK_IAM = mechanism, config} = _sasl_opts) do
    with {:ok, config} <- KafkaMskAuth.adapt_auth_config(config) do
      :ok = handshake(sock, mod, timeout, client_id, mechanism)

      client_final_msg =
        @signed_payload_generator.get_signed_payload(
          mechanism,
          host,
          DateTime.utc_now(),
          config
        )

      server_final_msg = send_recv(sock, mod, client_id, timeout, client_final_msg)

      case @kpro_lib.find(:error_code, server_final_msg) do
        :no_error -> :ok
        other -> {:error, other}
      end
    end
  end

  def auth(_host, _sock, _mod, _client_id, _timeout, _sasl_opts) do
    {:error, "Invalid SASL mechanism"}
  end

  defp send_recv(sock, mod, client_id, timeout, payload) do
    req = @kpro_lib.make(:sasl_authenticate, _auth_req_vsn = 0, [{:auth_bytes, payload}])
    rsp = @kpro_lib.send_and_recv(req, sock, mod, client_id, timeout)

    Logger.debug("Final Auth Response from server - #{inspect(rsp)}")

    rsp
  end

  defp cs([]), do: "[]"
  defp cs([x]), do: x
  defp cs([h | t]), do: [h, "," | cs(t)]

  defp handshake(sock, mod, timeout, client_id, mechanism, vsn \\ @handshake_version) do
    req = @kpro_lib.make(:sasl_handshake, vsn, [{:mechanism, mechanism}])
    rsp = @kpro_lib.send_and_recv(req, sock, mod, client_id, timeout)
    error_code = @kpro_lib.find(:error_code, rsp)

    Logger.debug("Error Code field in initial handshake response : #{error_code}")

    case error_code do
      :no_error ->
        :ok

      :unsupported_sasl_mechanism ->
        enabled_mechanisms = @kpro_lib.find(:mechanisms, rsp)
        "sasl mechanism #{mechanism} is not enabled in kafka, "
        "enabled mechanism(s): #{cs(enabled_mechanisms)}"

      other ->
        other
    end
  end
end
